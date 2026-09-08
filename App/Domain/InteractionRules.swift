import Foundation

struct DraftIssue: Equatable {
    let field: String
    let message: String
}

@MainActor extension CalculatorDraft {
    func firstIssue(locale: Locale) -> DraftIssue? {
        func issue(_ field: String, _ key: String) -> DraftIssue { DraftIssue(field: field, message: key) }
        for field in profile.dimensionFields {
            guard let text = dimensionTexts[field], let value = DecimalParser.double(text, locale: locale), value.finitePositive else {
                return issue(field.rawValue, "ui.positive_dimension")
            }
        }
        if DecimalParser.double(lengthText, locale: locale)?.finitePositive != true { return issue("length", "error.invalid_length") }
        if !(1...1_000_000).contains(quantity) { return issue("quantity", "ui.quantity_range") }
        if DecimalParser.double(densityText, locale: locale)?.finitePositive != true { return issue("density", "error.invalid_density") }
        if let waste = DecimalParser.double(wasteText, locale: locale), (0...1000).contains(waste) {} else { return issue("waste", "ui.waste_range") }
        if case .failure(let error) = result(locale: locale) {
            switch error {
            case .wallTooThick: return issue(DimensionField.wallThickness.rawValue, "ui.wall_limit")
            case .flangeTooThick: return issue(DimensionField.flangeThickness.rawValue, "ui.flange_limit")
            case .webTooThick: return issue(DimensionField.webThickness.rawValue, "ui.web_limit")
            case .invalid(let field), .missing(let field): return issue(field.rawValue, "ui.positive_dimension")
            default: return issue("geometry", "error.invalid_result")
            }
        }
        for (field, raw) in [("price", unitPriceText), ("fees", processingFeeText), ("fees", otherFeeText)] {
            if PricingInputValidator.nonnegative(raw, locale: locale) == nil { return issue(field, "ui.nonnegative_amount") }
        }
        if priceNeedsReview { return issue("price", "workflow.price_review") }
        return nil
    }
}

enum SelectionRules {
    static func addingVisible(_ visible: [UUID], to selection: Set<UUID>) -> Set<UUID> { selection.union(visible) }
}

struct QuoteLineChange: Identifiable {
    enum Kind: String { case added, modified, removed }
    let id: UUID
    let kind: Kind
    let old: QuoteSnapshotPayload.Line?
    let new: QuoteSnapshotPayload.Line?
}

enum QuoteComparison {
    static func changes(from old: QuoteSnapshotPayload, to new: QuoteSnapshotPayload) -> [QuoteLineChange] {
        let before = Dictionary(uniqueKeysWithValues: old.lines.map { ($0.itemID, $0) })
        let after = Set(new.lines.map(\.itemID))
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        var changes: [QuoteLineChange] = []
        for line in new.lines {
            if let prior = before[line.itemID] {
                if (try? encoder.encode(prior)) != (try? encoder.encode(line)) { changes.append(.init(id: line.itemID, kind: .modified, old: prior, new: line)) }
            } else { changes.append(.init(id: line.itemID, kind: .added, old: nil, new: line)) }
        }
        for line in old.lines where !after.contains(line.itemID) { changes.append(.init(id: line.itemID, kind: .removed, old: line, new: nil)) }
        return changes
    }
}
