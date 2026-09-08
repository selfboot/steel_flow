import Foundation
import SwiftData

extension AppFormatters {
    static func mass(_ kg: Double, system: UnitSystem, locale: Locale) -> String {
        let unit = system.massUnit
        return "\(number(unit.fromKilograms(kg), maximumFractionDigits: 3, locale: locale)) \(unit.rawValue)"
    }
}

enum PriceBasisConversion {
    static func convert(_ value: Decimal, from: PriceBasis, to: PriceBasis) -> Decimal? {
        if from == to { return value }
        switch (from, to) {
        case (.perKilogram, .perPound): return value * Decimal(string: "0.45359237")!
        case (.perPound, .perKilogram): return value / Decimal(string: "0.45359237")!
        case (.perMeter, .perFoot): return value * Decimal(string: "0.3048")!
        case (.perFoot, .perMeter): return value / Decimal(string: "0.3048")!
        default: return nil
        }
    }

    @MainActor
    static func migrate(_ item: CalculationItemEntity, from: String, to: String, mode: CurrencyChangeMode, rate: Decimal?) -> Bool {
        guard item.isPricingValid else { return false }
        if mode == .convert, rate.map({ $0 > 0 }) != true { return false }
        switch mode {
        case .keepAmounts: break
        case .clearAmounts:
            item.unitPriceText = "0"; item.processingFeeText = "0"; item.otherFeeText = "0"
        case .convert:
            guard let rate else { return false }
            // Unit prices retain precision; only totals and fixed fees use currency rounding.
            item.unitPriceText = (item.unitPrice * rate).description
            item.processingFeeText = CurrencyRules.round(item.processingFee * rate, currencyCode: to).description
            item.otherFeeText = CurrencyRules.round(item.otherFee * rate, currencyCode: to).description
        }
        item.priceSource = .manual
        item.priceSourceName = mode == .clearAmounts ? "" : "\(from) → \(to)" + (rate.map { " × \($0)" } ?? "")
        item.priceRegion = ""; item.priceIncludesTax = false; item.priceEffectiveAt = .now
        return true
    }
}

@MainActor
extension CalculatorDraft {
    func editStockLength(_ text: String) {
        if text != lengthText && priceBasis == .perPiece && priceSource == .history && unitPriceText != "0" { priceNeedsReview = true }
        lengthText = text
    }
    func clearPrice() {
        unitPriceText = "0"; priceSource = .manual; priceSourceName = ""; priceRegion = ""
        materialGrade = ""; priceIncludesTax = false; priceEffectiveAt = .now; priceNeedsReview = false
    }
}

@MainActor
extension CalculationItemEntity {
    func copyItem(sortIndex: Int? = nil) -> CalculationItemEntity {
        CalculationItemEntity(profile: profile, geometry: geometry, materialID: materialID, materialName: materialName,
            densityKgPerM3: densityKgPerM3, lengthValue: lengthValue, lengthUnit: lengthUnit, quantity: quantity,
            wastePercent: wastePercent, priceBasis: priceBasis, unitPrice: unitPrice, processingFee: processingFee,
            otherFee: otherFee, priceSource: priceSource, priceSourceName: priceSourceName, priceRegion: priceRegion,
            materialGrade: materialGrade, priceIncludesTax: priceIncludesTax, priceEffectiveAt: priceEffectiveAt,
            description: descriptionText, internalNote: internalNote, sortIndex: sortIndex ?? self.sortIndex)
    }
}

enum PriceApplicability {
    static func matches(profile: ProfileKind, geometry: GeometryInput?, entryProfile: String?, entryGeometry: Data?, lengthMeters: Double? = nil, entryLengthMeters: Double? = nil) -> Bool {
        if let expected = entryLengthMeters {
            guard let lengthMeters, abs(lengthMeters - expected) <= max(1e-10, expected * 1e-9) else { return false }
        }
        guard let entryProfile, !entryProfile.isEmpty else { return entryGeometry == nil }
        guard entryProfile == profile.rawValue else { return false }
        guard let entryGeometry else { return true }
        guard let geometry, let saved = try? JSONDecoder().decode(GeometryInput.self, from: entryGeometry) else { return false }
        for field in profile.dimensionFields {
            guard let a = saved.values[field], let b = geometry.values[field] else { return false }
            let lhs = field == .customArea ? saved.areaUnit.toSquareMeters(a) : saved.lengthUnit.toMeters(a)
            let rhs = field == .customArea ? geometry.areaUnit.toSquareMeters(b) : geometry.lengthUnit.toMeters(b)
            guard abs(lhs - rhs) <= max(1e-12, abs(lhs) * 1e-9) else { return false }
        }
        return true
    }
    static func description(profileRaw: String?, geometryData: Data?, locale: Locale) -> String {
        guard let raw = profileRaw, let profile = ProfileKind(rawValue: raw) else { return AppLocalization.text("workflow.all_specs", locale: locale) }
        let title = AppLocalization.text("profile." + raw, locale: locale)
        guard let data = geometryData, let geometry = try? JSONDecoder().decode(GeometryInput.self, from: data) else { return title }
        let values = profile.dimensionFields.compactMap { field in geometry.values[field].map { AppFormatters.number($0, maximumFractionDigits: 6, locale: locale) } }.joined(separator: " × ")
        return title + " · " + values + " " + (profile == .customArea ? geometry.areaUnit.rawValue : geometry.lengthUnit.rawValue)
    }
}
