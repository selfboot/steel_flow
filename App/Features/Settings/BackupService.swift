import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import CryptoKit

extension UTType {
    static let steelFlowBackup = UTType(exportedAs: "com.steelflow.backup", conformingTo: .json)
}

struct SteelFlowBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.steelFlowBackup, .json] }
    var data: Data

    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct BackupEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let appVersion: String
    let createdAt: Date
    let checksumSHA256: String
    let payload: BackupPayload
}

struct BackupPayload: Codable, Sendable {
    let materials: [MaterialBackup]
    let projects: [ProjectBackup]
    let company: CompanyBackup?
    let priceBook: [PriceBookBackup]?
}

struct PriceBookBackup: Codable, Sendable {
    let name: String
    let materialID: String
    let materialName: String
    let materialGrade: String
    let supplier: String
    let region: String
    let currencyCode: String
    let priceBasisRaw: String
    let unitPriceText: String
    let includesTax: Bool
    let effectiveAt: Date
    let note: String
}

struct MaterialBackup: Codable, Sendable {
    let id: String
    let name: String
    let densityKgPerM3: Double
    let note: String
}

struct ProjectBackup: Codable, Sendable {
    let name: String
    let projectNumber: String
    let customerName: String
    let quoteLanguage: String
    let unitSystemRaw: String
    let currencyCode: String
    let paperSizeRaw: String
    let taxPercentText: String
    let markupPercentText: String
    let profitModeRaw: String?
    let validDays: Int
    let terms: String
    let notes: String
    let isArchived: Bool
    let items: [ItemBackup]
}

struct ItemBackup: Codable, Sendable {
    let profileRaw: String
    let geometry: GeometryInput
    let materialID: String
    let materialName: String
    let densityKgPerM3: Double
    let lengthValue: Double
    let lengthUnitRaw: String
    let quantity: Int
    let wastePercent: Double
    let priceBasisRaw: String
    let unitPriceText: String
    let processingFeeText: String
    let otherFeeText: String
    let priceSourceRaw: String?
    let priceSourceName: String?
    let priceRegion: String?
    let materialGrade: String?
    let priceIncludesTax: Bool?
    let priceEffectiveAt: Date?
    let descriptionText: String
    let internalNote: String
    let sortIndex: Int
}

struct CompanyBackup: Codable, Sendable {
    let companyName: String
    let contactName: String
    let email: String
    let phone: String
    let address: String
}

enum BackupError: LocalizedError, Equatable {
    case unsupportedVersion
    case checksumMismatch
    case corrupt
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: String(localized: "backup.error.version")
        case .checksumMismatch: String(localized: "backup.error.checksum")
        case .corrupt: String(localized: "backup.error.corrupt")
        }
    }
}

@MainActor
enum BackupService {
    private static let currentSchemaVersion = 2
    private static let supportedSchemaVersions = 1...currentSchemaVersion

    static func makeDocument(projects: [ProjectEntity], materials: [MaterialEntity], company: CompanyProfileEntity?, priceBook: [PriceBookEntryEntity] = []) throws -> SteelFlowBackupDocument {
        let payload = BackupPayload(
            materials: materials.filter { !$0.isBuiltIn }.map { .init(id: $0.id, name: $0.name, densityKgPerM3: $0.densityKgPerM3, note: $0.note) },
            projects: projects.map(projectBackup),
            company: company.map { .init(companyName: $0.companyName, contactName: $0.contactName, email: $0.email, phone: $0.phone, address: $0.address) },
            priceBook: priceBook.map {
                .init(name: $0.name, materialID: $0.materialID, materialName: $0.materialName, materialGrade: $0.materialGrade,
                      supplier: $0.supplier, region: $0.region, currencyCode: $0.currencyCode, priceBasisRaw: $0.priceBasisRaw,
                      unitPriceText: $0.unitPriceText, includesTax: $0.includesTax, effectiveAt: $0.effectiveAt, note: $0.note)
            }
        )
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let payloadData = try encoder.encode(payload)
        let checksum = SHA256.hash(data: payloadData).map { String(format: "%02x", $0) }.joined()
        let envelope = BackupEnvelope(schemaVersion: currentSchemaVersion, appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", createdAt: .now, checksumSHA256: checksum, payload: payload)
        return SteelFlowBackupDocument(data: try encoder.encode(envelope))
    }

    static func preview(data: Data) throws -> (projects: Int, materials: Int) {
        let envelope = try decodeAndValidate(data)
        return (envelope.payload.projects.count, envelope.payload.materials.count)
    }

    static func importCopy(data: Data, into context: ModelContext) throws -> (projects: Int, materials: Int) {
        let envelope = try decodeAndValidate(data)
        var reservedMaterialIDs = Set(try context.fetch(FetchDescriptor<MaterialEntity>()).map(\.id))
        var materialIDMap: [String: String] = [:]
        var importedMaterials: [MaterialEntity] = []
        var importedProjects: [ProjectEntity] = []
        var importedPrices: [PriceBookEntryEntity] = []

        for material in envelope.payload.materials {
            guard !material.id.isEmpty,
                  materialIDMap[material.id] == nil,
                  !material.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  material.densityKgPerM3.finitePositive,
                  material.densityKgPerM3 < 100_000 else { throw BackupError.corrupt }
            let id = reservedMaterialIDs.contains(material.id) ? UUID().uuidString : material.id
            reservedMaterialIDs.insert(id)
            materialIDMap[material.id] = id
            importedMaterials.append(MaterialEntity(id: id, name: material.name, densityKgPerM3: material.densityKgPerM3, note: material.note))
        }

        for source in envelope.payload.projects {
            guard let currencyCode = CurrencyRules.normalizedCode(source.currencyCode),
                  ["en", "zh-Hans"].contains(source.quoteLanguage),
                  let unitSystem = UnitSystem(rawValue: source.unitSystemRaw),
                  let paperSize = PaperSize(rawValue: source.paperSizeRaw),
                  (1...365).contains(source.validDays) else { throw BackupError.corrupt }
            let profitMode: ProfitMode
            if let raw = source.profitModeRaw {
                guard let decoded = ProfitMode(rawValue: raw) else { throw BackupError.corrupt }
                profitMode = decoded
            } else {
                profitMode = .markup
            }
            let project = ProjectEntity(
                name: source.name + " " + String(localized: "backup.imported_suffix"),
                projectNumber: source.projectNumber + "-COPY",
                customerName: source.customerName,
                quoteLanguage: source.quoteLanguage,
                unitSystem: unitSystem,
                currencyCode: currencyCode,
                paperSize: paperSize
            )
            project.taxPercentText = source.taxPercentText
            project.markupPercentText = source.markupPercentText
            project.profitMode = profitMode
            guard project.isPricingPolicyValid else { throw BackupError.corrupt }
            project.validDays = source.validDays
            project.terms = source.terms
            project.notes = source.notes
            project.isArchived = source.isArchived
            for sourceItem in source.items {
                guard let profile = ProfileKind(rawValue: sourceItem.profileRaw),
                      let lengthUnit = LengthUnit(rawValue: sourceItem.lengthUnitRaw),
                      let priceBasis = PriceBasis(rawValue: sourceItem.priceBasisRaw),
                      sourceItem.densityKgPerM3.finitePositive,
                      sourceItem.densityKgPerM3 < 100_000,
                      sourceItem.lengthValue.finitePositive,
                      (1...1_000_000).contains(sourceItem.quantity),
                      sourceItem.wastePercent.isFinite,
                      (0...1_000).contains(sourceItem.wastePercent),
                      let unitPrice = PricingInputValidator.nonnegative(sourceItem.unitPriceText, locale: Locale(identifier: "en_US_POSIX")),
                      let processingFee = PricingInputValidator.nonnegative(sourceItem.processingFeeText, locale: Locale(identifier: "en_US_POSIX")),
                      let otherFee = PricingInputValidator.nonnegative(sourceItem.otherFeeText, locale: Locale(identifier: "en_US_POSIX")) else { throw BackupError.corrupt }
                let priceSource: PriceSource
                if let raw = sourceItem.priceSourceRaw {
                    guard let decoded = PriceSource(rawValue: raw) else { throw BackupError.corrupt }
                    priceSource = decoded
                } else {
                    priceSource = .manual
                }
                let item = CalculationItemEntity(
                    profile: profile,
                    geometry: sourceItem.geometry,
                    materialID: materialIDMap[sourceItem.materialID] ?? sourceItem.materialID,
                    materialName: sourceItem.materialName,
                    densityKgPerM3: sourceItem.densityKgPerM3,
                    lengthValue: sourceItem.lengthValue,
                    lengthUnit: lengthUnit,
                    quantity: sourceItem.quantity,
                    wastePercent: sourceItem.wastePercent,
                    priceBasis: priceBasis,
                    unitPrice: unitPrice,
                    processingFee: processingFee,
                    otherFee: otherFee,
                    priceSource: priceSource,
                    priceSourceName: sourceItem.priceSourceName ?? "",
                    priceRegion: sourceItem.priceRegion ?? "",
                    materialGrade: sourceItem.materialGrade ?? "",
                    priceIncludesTax: sourceItem.priceIncludesTax ?? false,
                    priceEffectiveAt: sourceItem.priceEffectiveAt,
                    description: sourceItem.descriptionText,
                    internalNote: sourceItem.internalNote,
                    sortIndex: sourceItem.sortIndex
                )
                guard (try? item.calculation()) != nil else { throw BackupError.corrupt }
                project.items.append(item)
            }
            importedProjects.append(project)
        }

        for source in envelope.payload.priceBook ?? [] {
            guard let currency = CurrencyRules.normalizedCode(source.currencyCode),
                  let priceBasis = PriceBasis(rawValue: source.priceBasisRaw),
                  !source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let price = PricingInputValidator.nonnegative(source.unitPriceText, locale: Locale(identifier: "en_US_POSIX")) else { throw BackupError.corrupt }
            importedPrices.append(PriceBookEntryEntity(
                name: source.name,
                materialID: materialIDMap[source.materialID] ?? source.materialID,
                materialName: source.materialName,
                materialGrade: source.materialGrade,
                supplier: source.supplier,
                region: source.region,
                currencyCode: currency,
                priceBasis: priceBasis,
                unitPrice: price,
                includesTax: source.includesTax,
                effectiveAt: source.effectiveAt,
                note: source.note
            ))
        }

        let existingCompany = try context.fetch(FetchDescriptor<CompanyProfileEntity>()).first
        let shouldImportCompany = existingCompany.map {
            $0.companyName.isEmpty && $0.contactName.isEmpty && $0.email.isEmpty && $0.phone.isEmpty && $0.address.isEmpty
        } ?? true

        do {
            importedMaterials.forEach(context.insert)
            importedProjects.forEach(context.insert)
            importedPrices.forEach(context.insert)

            if let source = envelope.payload.company {
                if shouldImportCompany {
                    let company = existingCompany ?? CompanyProfileEntity()
                    company.companyName = source.companyName
                    company.contactName = source.contactName
                    company.email = source.email
                    company.phone = source.phone
                    company.address = source.address
                    company.updatedAt = .now
                    if existingCompany == nil { context.insert(company) }
                }
            }

            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        return (envelope.payload.projects.count, envelope.payload.materials.count)
    }

    private static func decodeAndValidate(_ data: Data) throws -> BackupEnvelope {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(BackupEnvelope.self, from: data) else { throw BackupError.corrupt }
        guard supportedSchemaVersions.contains(envelope.schemaVersion) else { throw BackupError.unsupportedVersion }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let payloadData: Data
        if envelope.schemaVersion == 1 {
            // v1 encoded enum-keyed dictionaries as order-sensitive arrays. Hash
            // the payload bytes stored in the file so decoding cannot reorder them.
            guard let originalPayload = rawPayloadData(in: data) else { throw BackupError.corrupt }
            payloadData = originalPayload
        } else {
            guard let canonicalPayload = try? encoder.encode(envelope.payload) else { throw BackupError.corrupt }
            payloadData = canonicalPayload
        }
        let checksum = SHA256.hash(data: payloadData).map { String(format: "%02x", $0) }.joined()
        guard checksum == envelope.checksumSHA256 else { throw BackupError.checksumMismatch }
        return envelope
    }

    private static func rawPayloadData(in data: Data) -> Data? {
        let marker = Data("\"payload\":".utf8)
        guard let markerRange = data.range(of: marker) else { return nil }
        let bytes = [UInt8](data)
        var index = markerRange.upperBound
        while index < bytes.count, [9, 10, 13, 32].contains(bytes[index]) { index += 1 }
        guard index < bytes.count, bytes[index] == 123 else { return nil } // {

        let start = index
        var objectDepth = 0
        var isInString = false
        var isEscaped = false
        while index < bytes.count {
            let byte = bytes[index]
            if isInString {
                if isEscaped {
                    isEscaped = false
                } else if byte == 92 { // \\
                    isEscaped = true
                } else if byte == 34 { // "
                    isInString = false
                }
            } else if byte == 34 {
                isInString = true
            } else if byte == 123 {
                objectDepth += 1
            } else if byte == 125 {
                objectDepth -= 1
                if objectDepth == 0 {
                    return data.subdata(in: start..<(index + 1))
                }
            }
            index += 1
        }
        return nil
    }

    private static func projectBackup(_ project: ProjectEntity) -> ProjectBackup {
        .init(
            name: project.name, projectNumber: project.projectNumber, customerName: project.customerName,
            quoteLanguage: project.quoteLanguage, unitSystemRaw: project.unitSystemRaw, currencyCode: project.currencyCode,
            paperSizeRaw: project.paperSizeRaw, taxPercentText: project.taxPercentText, markupPercentText: project.markupPercentText, profitModeRaw: project.profitModeRaw,
            validDays: project.validDays, terms: project.terms, notes: project.notes, isArchived: project.isArchived,
            items: project.items.map { item in
                .init(profileRaw: item.profileRaw, geometry: item.geometry, materialID: item.materialID, materialName: item.materialName,
                      densityKgPerM3: item.densityKgPerM3, lengthValue: item.lengthValue, lengthUnitRaw: item.lengthUnitRaw,
                      quantity: item.quantity, wastePercent: item.wastePercent, priceBasisRaw: item.priceBasisRaw,
                      unitPriceText: item.unitPriceText, processingFeeText: item.processingFeeText, otherFeeText: item.otherFeeText,
                      priceSourceRaw: item.priceSourceRaw, priceSourceName: item.priceSourceName, priceRegion: item.priceRegion,
                      materialGrade: item.materialGrade, priceIncludesTax: item.priceIncludesTax, priceEffectiveAt: item.priceEffectiveAt,
                      descriptionText: item.descriptionText, internalNote: item.internalNote, sortIndex: item.sortIndex)
            }
        )
    }
}
