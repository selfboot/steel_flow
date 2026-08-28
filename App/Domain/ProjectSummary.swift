import Foundation

struct ProjectLineSummary: Identifiable {
    let id: UUID
    let item: CalculationItemEntity
    let result: CalculationResult
    let materialSubtotal: Decimal
    let customerQuoteAmount: Decimal
}

struct ProjectSummary {
    let lines: [ProjectLineSummary]
    let netMassKg: Double
    let adjustedMassKg: Double
    let pricing: PricingResult
    let invalidItemCount: Int
    let isPricingPolicyValid: Bool
}

enum ProjectCalculator {
    static func summarize(_ project: ProjectEntity) -> ProjectSummary {
        var lines: [ProjectLineSummary] = []
        var invalid = 0
        for item in project.items.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            guard item.isPricingValid, let result = try? item.calculation() else { invalid += 1; continue }
            let materialSubtotal = PricingCalculator.lineSubtotal(
                unitPrice: item.unitPrice,
                basis: item.priceBasis,
                result: result,
                lengthMeters: item.lengthUnit.toMeters(item.lengthValue),
                quantity: item.quantity,
                currencyCode: project.currencyCode
            )
            lines.append(.init(id: item.id, item: item, result: result, materialSubtotal: materialSubtotal, customerQuoteAmount: 0))
        }
        let subtotal = lines.reduce(Decimal.zero) { $0 + $1.materialSubtotal }
        let processing = lines.reduce(Decimal.zero) { $0 + CurrencyRules.round($1.item.processingFee, currencyCode: project.currencyCode) }
        let other = lines.reduce(Decimal.zero) { $0 + CurrencyRules.round($1.item.otherFee, currencyCode: project.currencyCode) }
        let pricing = PricingCalculator.total(
            subtotal: subtotal,
            processingFee: processing,
            otherFee: other,
            profitPercent: project.markupPercent,
            profitMode: project.profitMode,
            taxPercent: project.taxPercent,
            currencyCode: project.currencyCode
        )
        let customerLines = allocateCustomerQuoteAmounts(lines: lines, preTax: pricing.preTax, currencyCode: project.currencyCode)
        return ProjectSummary(
            lines: customerLines,
            netMassKg: lines.reduce(0) { $0 + $1.result.totalMassKg },
            adjustedMassKg: lines.reduce(0) { $0 + $1.result.wasteAdjustedMassKg },
            pricing: pricing,
            invalidItemCount: invalid,
            isPricingPolicyValid: project.isPricingPolicyValid
        )
    }

    private static func allocateCustomerQuoteAmounts(lines: [ProjectLineSummary], preTax: Decimal, currencyCode: String) -> [ProjectLineSummary] {
        guard !lines.isEmpty else { return [] }
        let bases = lines.map {
            $0.materialSubtotal +
            CurrencyRules.round($0.item.processingFee, currencyCode: currencyCode) +
            CurrencyRules.round($0.item.otherFee, currencyCode: currencyCode)
        }
        let totalBase = bases.reduce(Decimal.zero, +)
        var allocated = Decimal.zero
        return lines.enumerated().map { index, line in
            let amount: Decimal
            if index == lines.count - 1 {
                amount = preTax - allocated
            } else if totalBase > 0 {
                amount = CurrencyRules.round(preTax * bases[index] / totalBase, currencyCode: currencyCode)
                allocated += amount
            } else {
                amount = 0
            }
            return .init(
                id: line.id,
                item: line.item,
                result: line.result,
                materialSubtotal: line.materialSubtotal,
                customerQuoteAmount: amount
            )
        }
    }
}
