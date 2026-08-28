import XCTest
import SwiftData
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

    func testTamperedBackupFailsChecksum() throws {
        let project = ProjectEntity(name: "Source")
        let document = try BackupService.makeDocument(projects: [project], materials: [], company: nil)
        var text = String(decoding: document.data, as: UTF8.self)
        text = text.replacingOccurrences(of: "Source", with: "Changed")
        XCTAssertThrowsError(try BackupService.preview(data: Data(text.utf8))) {
            XCTAssertEqual($0 as? BackupError, .checksumMismatch)
        }
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
