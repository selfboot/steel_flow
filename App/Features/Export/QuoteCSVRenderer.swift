import Foundation

enum QuoteCSVKind: String, CaseIterable, Identifiable {
    case customer, procurement, cutting, internalCosts
    var id: String { rawValue }
    var title: String { "workflow.csv." + rawValue }
}

enum QuoteCSVRenderer {
    static func data(_ quote: QuoteSnapshotPayload, kind: QuoteCSVKind) -> Data {
        func cell(_ value: String, userText: Bool = false) -> String {
            let guarded = userText && value.trimmingCharacters(in: .whitespacesAndNewlines).first.map({ "=+-@".contains($0) }) == true ? "'" + value : value
            return "\"" + guarded.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        var header = ["row_type", "description", "profile", "material", "grade", "dimensions", "length_value", "length_unit", "quantity", "total_mass_kg"]
        if kind == .customer { header += ["sales_price_per_piece", "sales_amount_before_tax", "currency"] }
        if kind == .procurement || kind == .internalCosts { header += ["waste_percent", "purchase_price", "price_basis", "currency", "supplier", "price_date", "includes_tax_record_only"] }
        if kind == .internalCosts { header += ["material_cost", "processing_fee", "other_fee", "internal_note"] }
        if kind == .customer || kind == .internalCosts { header += ["project_pre_tax", "project_tax", "project_total"] }
        if kind == .internalCosts { header += ["project_profit"] }
        var rows = [header.joined(separator: ",")]
        for line in quote.lines {
            let dimensions = line.geometry.values.keys.sorted { $0.rawValue < $1.rawValue }.map {
                $0.rawValue + "=" + String(line.geometry.values[$0] ?? 0) + " " + ($0 == .customArea ? line.geometry.areaUnit.rawValue : line.geometry.lengthUnit.rawValue)
            }.joined(separator: "; ")
            var cells = [cell("item"), cell(line.descriptionText, userText: true), cell(line.profile), cell(line.materialName, userText: true), cell(line.materialGrade, userText: true), cell(dimensions), cell(String(line.lengthValue)), cell(line.lengthUnit), cell(String(line.quantity)), cell(String(line.totalMassKg))]
            if kind == .customer { cells += [cell((line.customerQuoteAmount / Decimal(line.quantity)).description), cell(line.customerQuoteAmount.description), cell(quote.currencyCode)] }
            if kind == .procurement || kind == .internalCosts { cells += [cell(String(line.wastePercent)), cell(line.unitPrice.description), cell(line.priceBasis), cell(quote.currencyCode), cell(line.priceSourceName, userText: true), cell(line.priceEffectiveAt.map { ISO8601DateFormatter().string(from: $0) } ?? ""), cell(String(line.priceIncludesTax))] }
            if kind == .internalCosts { cells += [cell(line.materialSubtotal.description), cell(line.processingFee.description), cell(line.otherFee.description), cell(line.internalNote, userText: true)] }
            if kind == .customer || kind == .internalCosts { cells += ["", "", ""] }
            if kind == .internalCosts { cells += [""] }
            rows.append(cells.joined(separator: ","))
        }
        if kind == .customer || kind == .internalCosts {
            var summary = Array(repeating: "", count: header.count)
            summary[0] = cell("project_summary"); summary[1] = cell(quote.projectName, userText: true)
            for (key, value) in [("currency", quote.currencyCode), ("project_pre_tax", quote.totals.preTax.description), ("project_tax", quote.totals.tax.description), ("project_total", quote.totals.total.description)] {
                if let index = header.firstIndex(of: key) { summary[index] = cell(value) }
            }
            if kind == .internalCosts, let index = header.firstIndex(of: "project_profit") { summary[index] = cell(quote.totals.profit.description) }
            rows.append(summary.joined(separator: ","))
        }
        return Data(("\u{FEFF}" + rows.joined(separator: "\r\n") + "\r\n").utf8)
    }
    static func url(_ quote: QuoteSnapshotPayload, kind: QuoteCSVKind) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SteelFlow_\(kind.rawValue)_\(UUID().uuidString.prefix(8)).csv")
        try data(quote, kind: kind).write(to: url, options: .atomic)
        return url
    }
}
