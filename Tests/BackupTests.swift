import XCTest
import SwiftData
import CryptoKit
@testable import SteelFlow

@MainActor
final class BackupTests: XCTestCase {
    private func container() throws -> ModelContainer {
        let schema = Schema([
            MaterialEntity.self, PriceBookEntryEntity.self, ProjectEntity.self, CalculationItemEntity.self, CustomerEntity.self,
            CompanyProfileEntity.self, QuoteSnapshotEntity.self, AppPreferenceEntity.self
        ])
        return try ModelContainer(for: schema, configurations: [.init(schema: schema, isStoredInMemoryOnly: true)])
    }

    func testBackupRoundTripImportsCopiesWithoutOverwrite() throws {
        let sourceContainer = try container()
        let source = sourceContainer.mainContext
        let material = MaterialEntity(name: "Custom alloy", densityKgPerM3: 8_100)
        let project = ProjectEntity(name: "Source", projectNumber: "Q-7")
        project.profitMode = .margin
        project.items.append(CalculationItemEntity(
            profile: .squareBar,
            geometry: .init(values: [.side: 20], lengthUnit: .millimeter),
            materialID: material.id,
            materialName: material.name,
            densityKgPerM3: material.densityKgPerM3,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 3,
            wastePercent: 2,
            priceBasis: .perKilogram,
            unitPrice: 5
        ))
        let price = PriceBookEntryEntity(name: "Supplier quote", materialID: material.id, materialName: material.name, materialGrade: "Q355B", supplier: "Acme", region: "Shanghai", currencyCode: "CNY", priceBasis: .perKilogram, unitPrice: 4.25, includesTax: true)
        source.insert(material); source.insert(project); source.insert(price); try source.save()

        let document = try BackupService.makeDocument(projects: [project], materials: [material], company: nil, priceBook: [price])
        let preview = try BackupService.preview(data: document.data)
        XCTAssertEqual(preview.projects, 1)
        XCTAssertEqual(preview.materials, 1)

        let destinationContainer = try container()
        let imported = try BackupService.importCopy(data: document.data, into: destinationContainer.mainContext)
        XCTAssertEqual(imported.projects, 1)
        XCTAssertEqual(imported.materials, 1)
        let projects = try destinationContainer.mainContext.fetch(FetchDescriptor<ProjectEntity>())
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.items.count, 1)
        XCTAssertTrue(projects.first?.projectNumber.hasSuffix("-COPY") == true)
        XCTAssertEqual(projects.first?.profitMode, .margin)
        let prices = try destinationContainer.mainContext.fetch(FetchDescriptor<PriceBookEntryEntity>())
        XCTAssertEqual(prices.count, 1)
        XCTAssertEqual(prices.first?.supplier, "Acme")
        XCTAssertEqual(prices.first?.unitPrice, Decimal(string: "4.25"))
    }

    func testNewBackupsUseStableSchemaVersionTwoAndStillReadLegacyVersionOneGeometry() throws {
        let project = ProjectEntity(name: "Schema")
        project.items.append(CalculationItemEntity(
            profile: .plate,
            geometry: .init(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 1,
            wastePercent: 0,
            priceBasis: .perKilogram,
            unitPrice: 2
        ))
        let document = try BackupService.makeDocument(projects: [project], materials: [], company: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(BackupEnvelope.self, from: document.data)
        XCTAssertEqual(envelope.schemaVersion, 2)

        var versionOneText = String(decoding: document.data, as: UTF8.self)
            .replacingOccurrences(of: "\"schemaVersion\":2", with: "\"schemaVersion\":1")
            .replacingOccurrences(
                of: "\"values\":{\"thickness\":10,\"width\":100}",
                with: "\"values\":[\"width\",100,\"thickness\",10]"
            )
        XCTAssertNotEqual(versionOneText, String(decoding: document.data, as: UTF8.self))
        XCTAssertTrue(versionOneText.contains("\"values\":[\"width\",100,\"thickness\",10]"))

        let payloadMarker = "\"payload\":"
        let schemaMarker = ",\"schemaVersion\":1}"
        let payloadStart = try XCTUnwrap(versionOneText.range(of: payloadMarker)?.upperBound)
        let payloadEnd = try XCTUnwrap(versionOneText.range(of: schemaMarker, options: .backwards)?.lowerBound)
        let legacyPayloadData = Data(versionOneText[payloadStart..<payloadEnd].utf8)
        let legacyChecksum = SHA256.hash(data: legacyPayloadData).map { String(format: "%02x", $0) }.joined()
        versionOneText = versionOneText.replacingOccurrences(of: envelope.checksumSHA256, with: legacyChecksum)

        let versionOneData = Data(versionOneText.utf8)
        XCTAssertEqual(try BackupService.preview(data: versionOneData).projects, 1)
    }

    func testTamperedBackupFailsChecksum() throws {
        let project = ProjectEntity(name: "Source")
        let document = try BackupService.makeDocument(projects: [project], materials: [], company: nil)
        var text = String(decoding: document.data, as: UTF8.self)
        text = text.replacingOccurrences(of: "Source", with: "Changed")
        XCTAssertThrowsError(try BackupService.preview(data: Data(text.utf8))) {
            XCTAssertEqual($0 as? BackupError, .checksumMismatch)
        }
    }

    func testSemanticallyInvalidBackupDoesNotPartiallyImportMaterials() throws {
        let material = MaterialEntity(name: "Valid material", densityKgPerM3: 8_100)
        let invalidProject = ProjectEntity(name: "Invalid project", currencyCode: "INVALID")
        let document = try BackupService.makeDocument(projects: [invalidProject], materials: [material], company: nil)
        let destination = try container()

        XCTAssertThrowsError(try BackupService.importCopy(data: document.data, into: destination.mainContext)) {
            XCTAssertEqual($0 as? BackupError, .corrupt)
        }
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<MaterialEntity>()).count, 0)
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<ProjectEntity>()).count, 0)
    }

    func testBackupRejectsInvalidItemGeometryBeforeAnyImport() throws {
        let material = MaterialEntity(name: "Valid material", densityKgPerM3: 7_850)
        let project = ProjectEntity(name: "Invalid geometry")
        project.items.append(CalculationItemEntity(
            profile: .roundTube,
            geometry: .init(values: [.outerDiameter: 10, .wallThickness: 6], lengthUnit: .millimeter),
            materialID: material.id,
            materialName: material.name,
            densityKgPerM3: material.densityKgPerM3,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 1,
            wastePercent: 0,
            priceBasis: .perKilogram,
            unitPrice: 5
        ))
        let document = try BackupService.makeDocument(projects: [project], materials: [material], company: nil)
        let destination = try container()

        XCTAssertThrowsError(try BackupService.importCopy(data: document.data, into: destination.mainContext)) {
            XCTAssertEqual($0 as? BackupError, .corrupt)
        }
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<MaterialEntity>()).count, 0)
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<ProjectEntity>()).count, 0)
    }

    func testBackupRejectsUnsupportedSemanticEnums() throws {
        let project = ProjectEntity(name: "Unsupported locale")
        project.quoteLanguage = "fr"
        let document = try BackupService.makeDocument(projects: [project], materials: [], company: nil)
        let destination = try container()

        XCTAssertThrowsError(try BackupService.importCopy(data: document.data, into: destination.mainContext)) {
            XCTAssertEqual($0 as? BackupError, .corrupt)
        }
        XCTAssertEqual(try destination.mainContext.fetch(FetchDescriptor<ProjectEntity>()).count, 0)
    }

    func testQuoteSnapshotPayloadPersistsAsImmutableAuditRecord() throws {
        let container = try container()
        let project = ProjectEntity(name: "Audit", currencyCode: "USD")
        project.items.append(CalculationItemEntity(
            profile: .plate,
            geometry: .init(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 1,
            wastePercent: 0,
            priceBasis: .perKilogram,
            unitPrice: 2
        ))
        container.mainContext.insert(project)
        let payload = try QuoteExportService.snapshotData(for: project, generatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        container.mainContext.insert(QuoteSnapshotEntity(projectID: project.id, payload: payload))
        try container.mainContext.save()

        let snapshots = try container.mainContext.fetch(FetchDescriptor<QuoteSnapshotEntity>())
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.engineVersion, CalculationEngine.version)
        XCTAssertEqual(snapshots.first?.payload, payload)
    }
}
