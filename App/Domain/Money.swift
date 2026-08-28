import Foundation

struct Money: Codable, Hashable, Sendable {
    var amount: Decimal
    var currencyCode: String
}

enum ProfitMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case markup
    case margin

    var id: String { rawValue }
    var localizationKey: LocalizedStringResource {
        switch self {
        case .markup: "profit_mode.markup"
        case .margin: "profit_mode.margin"
        }
    }
}

enum PriceSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case manual
    case history
    case marketReference

    var id: String { rawValue }
    var localizationKey: LocalizedStringResource {
        switch self {
        case .manual: "price_source.manual"
        case .history: "price_source.history"
        case .marketReference: "price_source.market_reference"
        }
    }
}

enum CurrencyChangeMode: String, CaseIterable, Identifiable, Sendable {
    case keepAmounts
    case convert
    case clearAmounts

    var id: String { rawValue }
    var localizationKey: LocalizedStringResource {
        switch self {
        case .keepAmounts: "currency_change.keep"
        case .convert: "currency_change.convert"
        case .clearAmounts: "currency_change.clear"
        }
    }
}

enum CurrencyRules {
    static func normalizedCode(_ value: String) -> String? {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Locale.commonISOCurrencyCodes.contains(code) else { return nil }
        return code
    }

    static func fractionDigits(for currencyCode: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.maximumFractionDigits
    }

    static func round(_ value: Decimal, currencyCode: String) -> Decimal {
        var source = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, fractionDigits(for: currencyCode), .bankers)
        return rounded
    }

    static func decimalFactor(_ value: Double) -> Decimal {
        guard value.isFinite else { return 0 }
        let text = String(format: "%.15g", locale: Locale(identifier: "en_US_POSIX"), value)
        return Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}

enum PricingInputValidator {
    static func nonnegative(_ text: String, locale: Locale = .current) -> Decimal? {
        guard let value = DecimalParser.parse(text, locale: locale), value >= 0 else { return nil }
        return value
    }

    static func percentage(_ text: String, mode: ProfitMode? = nil, locale: Locale = .current) -> Decimal? {
        guard let value = nonnegative(text, locale: locale), value <= 1_000 else { return nil }
        if mode == .margin, value >= 100 { return nil }
        return value
    }
}

@MainActor
enum CurrencyMigration {
    static func apply(to project: ProjectEntity, newCurrency: String, mode: CurrencyChangeMode, rate: Decimal? = nil) -> Bool {
        guard let normalized = CurrencyRules.normalizedCode(newCurrency), normalized != project.currencyCode else { return false }
        if mode == .convert, rate.map({ $0 > 0 }) != true { return false }
        let oldCurrency = project.currencyCode
        for item in project.items {
            switch mode {
            case .keepAmounts:
                item.priceSource = .manual
                item.priceSourceName = "\(oldCurrency)→\(normalized), no conversion"
                item.priceEffectiveAt = .now
            case .clearAmounts:
                item.unitPriceText = "0"
                item.processingFeeText = "0"
                item.otherFeeText = "0"
                item.priceSource = .manual
                item.priceSourceName = ""
                item.priceEffectiveAt = .now
            case .convert:
                guard let rate else { return false }
                if let value = item.validUnitPrice { item.unitPriceText = CurrencyRules.round(value * rate, currencyCode: normalized).description }
                if let value = item.validProcessingFee { item.processingFeeText = CurrencyRules.round(value * rate, currencyCode: normalized).description }
                if let value = item.validOtherFee { item.otherFeeText = CurrencyRules.round(value * rate, currencyCode: normalized).description }
                item.priceSource = .manual
                item.priceSourceName = "\(oldCurrency)→\(normalized) × \(rate)"
                item.priceEffectiveAt = .now
            }
        }
        project.currencyCode = normalized
        return true
    }
}

enum PricingCalculator {
    static func lineSubtotal(
        unitPrice: Decimal,
        basis: PriceBasis,
        result: CalculationResult,
        lengthMeters: Double,
        quantity: Int,
        currencyCode: String = "USD"
    ) -> Decimal {
        guard unitPrice >= 0, lengthMeters.isFinite, lengthMeters >= 0, quantity > 0 else { return 0 }
        let wasteFactor = result.totalMassKg > 0 ? result.wasteAdjustedMassKg / result.totalMassKg : 1
        let factor: Double
        switch basis {
        case .perKilogram: factor = result.wasteAdjustedMassKg
        case .perPound: factor = MassUnit.pound.fromKilograms(result.wasteAdjustedMassKg)
        case .perMeter: factor = lengthMeters * Double(quantity) * wasteFactor
        case .perFoot: factor = LengthUnit.foot.fromMeters(lengthMeters) * Double(quantity) * wasteFactor
        case .perPiece: factor = Double(quantity) * wasteFactor
        }
        return CurrencyRules.round(unitPrice * CurrencyRules.decimalFactor(factor), currencyCode: currencyCode)
    }

    static func total(
        subtotal: Decimal,
        processingFee: Decimal,
        otherFee: Decimal,
        profitPercent: Decimal,
        profitMode: ProfitMode,
        taxPercent: Decimal,
        currencyCode: String
    ) -> PricingResult {
        let materialSubtotal = CurrencyRules.round(subtotal, currencyCode: currencyCode)
        let processing = CurrencyRules.round(processingFee, currencyCode: currencyCode)
        let other = CurrencyRules.round(otherFee, currencyCode: currencyCode)
        let fees = processing + other
        let base = materialSubtotal + fees
        let profit: Decimal
        switch profitMode {
        case .markup:
            profit = CurrencyRules.round(base * profitPercent / 100, currencyCode: currencyCode)
        case .margin:
            guard profitPercent < 100 else {
                return PricingResult(materialSubtotal: materialSubtotal, fees: fees, profit: 0, preTax: base, tax: 0, total: base)
            }
            let sellingPrice = CurrencyRules.round(base / (1 - profitPercent / 100), currencyCode: currencyCode)
            profit = sellingPrice - base
        }
        let preTax = base + profit
        let tax = CurrencyRules.round(preTax * taxPercent / 100, currencyCode: currencyCode)
        return PricingResult(materialSubtotal: materialSubtotal, fees: fees, profit: profit, preTax: preTax, tax: tax, total: preTax + tax)
    }

    static func total(
        subtotal: Decimal,
        processingFee: Decimal,
        otherFee: Decimal,
        markupPercent: Decimal,
        taxPercent: Decimal,
        currencyCode: String = "USD"
    ) -> PricingResult {
        total(
            subtotal: subtotal,
            processingFee: processingFee,
            otherFee: otherFee,
            profitPercent: markupPercent,
            profitMode: .markup,
            taxPercent: taxPercent,
            currencyCode: currencyCode
        )
    }
}

struct PricingResult: Sendable, Equatable {
    var materialSubtotal: Decimal
    var fees: Decimal
    var profit: Decimal
    var preTax: Decimal
    var tax: Decimal
    var total: Decimal

    var markup: Decimal { profit }
}
