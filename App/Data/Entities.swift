import Foundation
import SwiftData

@Model
final class MaterialEntity {
    @Attribute(.unique) var id: String
    var name: String
    var nameKey: String?
    var densityKgPerM3: Double
    var note: String
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String, nameKey: String? = nil, densityKgPerM3: Double, note: String = "", isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.nameKey = nameKey
        self.densityKgPerM3 = densityKgPerM3
        self.note = note
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class ProjectEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectNumber: String
    var customerName: String
    var quoteLanguage: String
    var unitSystemRaw: String
    var currencyCode: String
    var paperSizeRaw: String
    var taxPercentText: String
    var markupPercentText: String
    var profitModeRaw: String = ProfitMode.markup.rawValue
    var validDays: Int
    var terms: String
    var notes: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var items: [CalculationItemEntity]

    init(
        id: UUID = UUID(),
        name: String,
        projectNumber: String = ProjectEntity.makeNumber(),
        customerName: String = "",
        quoteLanguage: String = "en",
        unitSystem: UnitSystem = .metric,
        currencyCode: String = "USD",
        paperSize: PaperSize = .a4
    ) {
        self.id = id
        self.name = name
        self.projectNumber = projectNumber
        self.customerName = customerName
        self.quoteLanguage = quoteLanguage
        self.unitSystemRaw = unitSystem.rawValue
        self.currencyCode = currencyCode
        self.paperSizeRaw = paperSize.rawValue
        self.taxPercentText = "0"
        self.markupPercentText = "0"
        self.profitModeRaw = ProfitMode.markup.rawValue
        self.validDays = 30
        self.terms = ""
        self.notes = ""
        self.isArchived = false
        self.createdAt = .now
        self.updatedAt = .now
        self.items = []
    }

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    var paperSize: PaperSize {
        get { PaperSize(rawValue: paperSizeRaw) ?? .a4 }
        set { paperSizeRaw = newValue.rawValue }
    }

    var profitMode: ProfitMode {
        get { ProfitMode(rawValue: profitModeRaw) ?? .markup }
        set { profitModeRaw = newValue.rawValue }
    }
    var validTaxPercent: Decimal? { PricingInputValidator.percentage(taxPercentText, locale: Locale(identifier: "en_US_POSIX")) }
    var validProfitPercent: Decimal? { PricingInputValidator.percentage(markupPercentText, mode: profitMode, locale: Locale(identifier: "en_US_POSIX")) }
    var taxPercent: Decimal { validTaxPercent ?? 0 }
    var markupPercent: Decimal { validProfitPercent ?? 0 }
    var isPricingPolicyValid: Bool { validTaxPercent != nil && validProfitPercent != nil }

    static func makeNumber(date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "Q-\(formatter.string(from: date))"
    }
}

@Model
final class CalculationItemEntity {
    @Attribute(.unique) var id: UUID
    var profileRaw: String
    var geometryData: Data
    var materialID: String
    var materialName: String
    var densityKgPerM3: Double
    var lengthValue: Double
    var lengthUnitRaw: String
    var quantity: Int
    var wastePercent: Double
    var priceBasisRaw: String
    var unitPriceText: String
    var processingFeeText: String
    var otherFeeText: String
    var priceSourceRaw: String = PriceSource.manual.rawValue
    var priceSourceName: String = ""
    var priceRegion: String = ""
    var materialGrade: String = ""
    var priceIncludesTax: Bool = false
    var priceEffectiveAt: Date?
    var descriptionText: String
    var internalNote: String
    var sortIndex: Int
    var calculationVersion: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        profile: ProfileKind,
        geometry: GeometryInput,
        materialID: String,
        materialName: String,
        densityKgPerM3: Double,
        lengthValue: Double,
        lengthUnit: LengthUnit,
        quantity: Int,
        wastePercent: Double,
        priceBasis: PriceBasis,
        unitPrice: Decimal,
        processingFee: Decimal = 0,
        otherFee: Decimal = 0,
        priceSource: PriceSource = .manual,
        priceSourceName: String = "",
        priceRegion: String = "",
        materialGrade: String = "",
        priceIncludesTax: Bool = false,
        priceEffectiveAt: Date? = nil,
        description: String = "",
        internalNote: String = "",
        sortIndex: Int = 0
    ) {
        self.id = id
        self.profileRaw = profile.rawValue
        self.geometryData = (try? JSONEncoder().encode(geometry)) ?? Data()
        self.materialID = materialID
        self.materialName = materialName
        self.densityKgPerM3 = densityKgPerM3
        self.lengthValue = lengthValue
        self.lengthUnitRaw = lengthUnit.rawValue
        self.quantity = quantity
        self.wastePercent = wastePercent
        self.priceBasisRaw = priceBasis.rawValue
        self.unitPriceText = unitPrice.description
        self.processingFeeText = processingFee.description
        self.otherFeeText = otherFee.description
        self.priceSourceRaw = priceSource.rawValue
        self.priceSourceName = priceSourceName
        self.priceRegion = priceRegion
        self.materialGrade = materialGrade
        self.priceIncludesTax = priceIncludesTax
        self.priceEffectiveAt = priceEffectiveAt
        self.descriptionText = description
        self.internalNote = internalNote
        self.sortIndex = sortIndex
        self.calculationVersion = CalculationEngine.version
        self.createdAt = .now
        self.updatedAt = .now
    }

    var profile: ProfileKind { ProfileKind(rawValue: profileRaw) ?? .plate }
    var geometry: GeometryInput { (try? JSONDecoder().decode(GeometryInput.self, from: geometryData)) ?? GeometryInput() }
    var lengthUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .meter }
    var priceBasis: PriceBasis { PriceBasis(rawValue: priceBasisRaw) ?? .perKilogram }
    var priceSource: PriceSource {
        get { PriceSource(rawValue: priceSourceRaw) ?? .manual }
        set { priceSourceRaw = newValue.rawValue }
    }
    var validUnitPrice: Decimal? { PricingInputValidator.nonnegative(unitPriceText, locale: Locale(identifier: "en_US_POSIX")) }
    var validProcessingFee: Decimal? { PricingInputValidator.nonnegative(processingFeeText, locale: Locale(identifier: "en_US_POSIX")) }
    var validOtherFee: Decimal? { PricingInputValidator.nonnegative(otherFeeText, locale: Locale(identifier: "en_US_POSIX")) }
    var isPricingValid: Bool { validUnitPrice != nil && validProcessingFee != nil && validOtherFee != nil }
    var unitPrice: Decimal { validUnitPrice ?? 0 }
    var processingFee: Decimal { validProcessingFee ?? 0 }
    var otherFee: Decimal { validOtherFee ?? 0 }

    @discardableResult
    func canonicalizePricing(locale: Locale) -> Bool {
        guard let unitPrice = PricingInputValidator.nonnegative(unitPriceText, locale: locale),
              let processingFee = PricingInputValidator.nonnegative(processingFeeText, locale: locale),
              let otherFee = PricingInputValidator.nonnegative(otherFeeText, locale: locale) else { return false }
        unitPriceText = unitPrice.description
        processingFeeText = processingFee.description
        otherFeeText = otherFee.description
        return true
    }

    func calculation() throws -> CalculationResult {
        try CalculationEngine.calculate(.init(
            profile: profile,
            geometry: geometry,
            lengthValue: lengthValue,
            lengthUnit: lengthUnit,
            quantity: quantity,
            densityKgPerM3: densityKgPerM3,
            wastePercent: wastePercent
        ))
    }
}

@Model
final class PriceBookEntryEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var materialID: String
    var materialName: String
    var materialGrade: String
    var supplier: String
    var region: String
    var currencyCode: String
    var priceBasisRaw: String
    var unitPriceText: String
    var includesTax: Bool
    var effectiveAt: Date
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        materialID: String = "",
        materialName: String = "",
        materialGrade: String = "",
        supplier: String = "",
        region: String = "",
        currencyCode: String,
        priceBasis: PriceBasis,
        unitPrice: Decimal,
        includesTax: Bool = false,
        effectiveAt: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.materialID = materialID
        self.materialName = materialName
        self.materialGrade = materialGrade
        self.supplier = supplier
        self.region = region
        self.currencyCode = currencyCode
        self.priceBasisRaw = priceBasis.rawValue
        self.unitPriceText = unitPrice.description
        self.includesTax = includesTax
        self.effectiveAt = effectiveAt
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
    }

    var priceBasis: PriceBasis {
        get { PriceBasis(rawValue: priceBasisRaw) ?? .perKilogram }
        set { priceBasisRaw = newValue.rawValue }
    }
    var unitPrice: Decimal { PricingInputValidator.nonnegative(unitPriceText, locale: Locale(identifier: "en_US_POSIX")) ?? 0 }
}

@Model
final class CustomerEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var phone: String
    var address: String
    var createdAt: Date

    init(name: String, email: String = "", phone: String = "", address: String = "") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.createdAt = .now
    }
}

@Model
final class CompanyProfileEntity {
    @Attribute(.unique) var id: String
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var address: String
    var updatedAt: Date

    init(id: String = "default", companyName: String = "", contactName: String = "", email: String = "", phone: String = "", address: String = "") {
        self.id = id
        self.companyName = companyName
        self.contactName = contactName
        self.email = email
        self.phone = phone
        self.address = address
        self.updatedAt = .now
    }
}

@Model
final class QuoteSnapshotEntity {
    @Attribute(.unique) var id: UUID
    var projectID: UUID
    var createdAt: Date
    var engineVersion: Int
    var payload: Data

    init(projectID: UUID, payload: Data) {
        self.id = UUID()
        self.projectID = projectID
        self.createdAt = .now
        self.engineVersion = CalculationEngine.version
        self.payload = payload
    }
}

@Model
final class AppPreferenceEntity {
    @Attribute(.unique) var id: String
    var languageCode: String
    var unitSystemRaw: String
    var currencyCode: String
    var paperSizeRaw: String

    init(id: String = "default", languageCode: String = "system", unitSystem: UnitSystem = .metric, currencyCode: String = "USD", paperSize: PaperSize = .a4) {
        self.id = id
        self.languageCode = languageCode
        self.unitSystemRaw = unitSystem.rawValue
        self.currencyCode = currencyCode
        self.paperSizeRaw = paperSize.rawValue
    }
}

enum PaperSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case a4
    case letter
    var id: String { rawValue }
}
