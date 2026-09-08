import Foundation
import UIKit

/// Renders frozen values only, including repeatable dates, units and branding.
@MainActor
enum QuotePDFRenderer {
    static func render(_ quote: QuoteSnapshotPayload) throws -> URL {
        let size = quote.paperSize == PaperSize.letter.rawValue ? CGSize(width: 612, height: 792) : CGSize(width: 595.2, height: 841.8)
        let locale = Locale(identifier: quote.quoteLanguage)
        let system = UnitSystem(rawValue: quote.unitSystemRaw ?? "") ?? .metric
        let margin: CGFloat = 36, contentWidth = size.width - 72
        let bodyFont = UIFont.systemFont(ofSize: 9)
        let lineHeight: CGFloat = 13
        let bottom = size.height - 55
        let showMass = quote.showMass ?? true
        let showUnitPrice = quote.showUnitPrice ?? false
        func l(_ key: String) -> String { AppLocalization.text(key, locale: locale) }
        func money(_ value: Decimal) -> String { AppFormatters.decimal(value, currencyCode: quote.currencyCode, locale: locale) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SteelFlow_\(quote.projectNumber.filter { $0.isLetter || $0.isNumber || $0 == "-" }.prefix(50))_\(UUID().uuidString.prefix(8)).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        var y: CGFloat = 36
        var page = 0
        func draw(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont = .systemFont(ofSize: 9), color: UIColor = .black) {
            (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: max(16, font.lineHeight + 2)), withAttributes: [.font: font, .foregroundColor: color])
        }
        // Explicit glyph wrapping makes even unbroken part numbers and long Chinese text flow.
        func wrap(_ text: String, width: CGFloat, font: UIFont = .systemFont(ofSize: 9)) -> [String] {
            var result: [String] = []
            for paragraph in text.components(separatedBy: "\n") {
                var line = ""
                for character in paragraph {
                    let candidate = line + String(character)
                    if !line.isEmpty && (candidate as NSString).size(withAttributes: [.font: font]).width > width {
                        result.append(line); line = String(character)
                    } else { line = candidate }
                }
                result.append(line)
            }
            return result
        }
        var widths: [CGFloat] = [contentWidth - 30 - 84, 30, 84]
        var headers = [l("quote.item"), l("quote.quantity"), l("quote.amount")]
        if showMass { widths[0] -= 68; widths.insert(68, at: widths.count - 1); headers.insert(l("quote.mass"), at: headers.count - 1) }
        if showUnitPrice { widths[0] -= 85; widths.insert(85, at: widths.count - 1); headers.insert(l("workflow.sales_unit_price"), at: headers.count - 1) }
        do {
            try renderer.writePDF(to: url) { context in
                @MainActor func tableHeader() {
                    UIColor(white: 0.9, alpha: 1).setFill()
                    context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 28))
                    var x = margin
                    for i in headers.indices {
                        for (j, text) in wrap(headers[i], width: widths[i] - 8).enumerated() {
                            draw(text, x: x + 4, y: y + 2 + CGFloat(j) * 12, width: widths[i] - 8)
                        }
                        x += widths[i]
                    }
                    y += 30
                }
                @MainActor func newPage(table: Bool = false) {
                    context.beginPage(); page += 1; y = margin
                    let footer = quote.includeBranding ? l("quote.generated_by") + " · " + l("quote.disclaimer") : l("quote.disclaimer")
                    for (i, line) in wrap(footer, width: contentWidth - 35, font: .systemFont(ofSize: 7)).enumerated() {
                        draw(line, x: margin, y: size.height - 39 + CGFloat(i) * 9, width: contentWidth - 35, font: .systemFont(ofSize: 7), color: .darkGray)
                    }
                    draw(String(page), x: size.width - 60, y: size.height - 38, width: 25)
                    if page > 1 {
                        draw(l("quote.title") + " · " + quote.projectNumber, x: margin, y: y, width: contentWidth)
                        y += 24
                    }
                    if table { tableHeader() }
                }
                @MainActor func paragraph(_ text: String, font: UIFont = .systemFont(ofSize: 10)) {
                    let height = ceil(font.lineHeight) + 4
                    for line in wrap(text, width: contentWidth, font: font) {
                        if y + height > bottom { newPage() }
                        draw(line, x: margin, y: y, width: contentWidth, font: font)
                        y += height
                    }
                    y += 5
                }
                newPage()
                if let data = quote.company?.logoData, let image = UIImage(data: data) {
                    let scale = min(100 / image.size.width, 48 / image.size.height)
                    image.draw(in: CGRect(x: margin, y: y, width: image.size.width * scale, height: image.size.height * scale)); y += 54
                }
                paragraph(quote.company?.companyName.isEmpty == false ? quote.company!.companyName : "SteelFlow", font: .boldSystemFont(ofSize: 18))
                if let company = quote.company {
                    let details = [company.contactName, company.phone, company.email, company.address].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !details.isEmpty { paragraph(details, font: .systemFont(ofSize: 9)) }
                }
                paragraph(l("quote.title") + " · " + quote.projectNumber, font: .boldSystemFont(ofSize: 16))
                paragraph(l("project.customer") + ": " + (quote.customerName.isEmpty ? "—" : quote.customerName))
                if let contact = quote.customerContact, !contact.isEmpty { paragraph(contact) }
                paragraph(AppFormatters.date(quote.generatedAt, locale: locale) + " · " + l("quote.valid_until") + ": " + AppFormatters.date(quote.validUntil, locale: locale))
                if y + 75 > bottom { newPage() }
                tableHeader()
                for (index, line) in quote.lines.enumerated() {
                    let geometryUnit = system.lengthUnit
                    let dimensions = (ProfileKind(rawValue: line.profile)?.dimensionFields ?? []).compactMap { field -> String? in
                        guard let value = line.geometry.values[field] else { return nil }
                        if field == .customArea {
                            let areaUnit: AreaUnit = system == .metric ? .squareMillimeter : .squareInch
                            return AppFormatters.number(areaUnit.fromSquareMeters(line.geometry.areaUnit.toSquareMeters(value)), maximumFractionDigits: 4, locale: locale) + " " + areaUnit.rawValue
                        }
                        return AppFormatters.number(geometryUnit.fromMeters(line.geometry.lengthUnit.toMeters(value)), maximumFractionDigits: 4, locale: locale) + " " + geometryUnit.rawValue
                    }.joined(separator: " × ")
                    let sourceLengthUnit = LengthUnit(rawValue: line.lengthUnit) ?? .meter
                    let length = system.stockLengthUnit.fromMeters(sourceLengthUnit.toMeters(line.lengthValue))
                    let spec = dimensions + " · " + l("calculator.length") + ": " + AppFormatters.number(length, maximumFractionDigits: 4, locale: locale) + " " + system.stockLengthUnit.rawValue
                    let title = line.descriptionText.isEmpty ? l("profile." + line.profile) : line.descriptionText
                    var cells = ["\(index + 1). " + title + "\n" + [line.materialName, line.materialGrade].filter { !$0.isEmpty }.joined(separator: " · ") + "\n" + spec, String(line.quantity), money(line.customerQuoteAmount)]
                    if showMass { cells.insert(AppFormatters.mass(line.totalMassKg, system: system, locale: locale), at: cells.count - 1) }
                    if showUnitPrice { cells.insert(money(line.customerQuoteAmount / Decimal(line.quantity)) + " / " + l("price_basis.per_piece"), at: cells.count - 1) }
                    let lines = cells.enumerated().map { wrap($0.element, width: widths[$0.offset] - 8, font: bodyFont) }
                    let count = lines.map(\.count).max() ?? 1
                    for row in 0..<count {
                        if y + lineHeight + 6 > bottom { newPage(table: true) }
                        var x = margin
                        for col in lines.indices {
                            if row < lines[col].count { draw(lines[col][row], x: x + 4, y: y, width: widths[col] - 8) }
                            x += widths[col]
                        }
                        y += lineHeight
                    }
                    y += 8
                    UIColor(white: 0.8, alpha: 1).setFill(); context.cgContext.fill(CGRect(x: margin, y: y - 4, width: contentWidth, height: 0.5))
                }
                if y + 85 > bottom { newPage() }
                y += 8
                paragraph(l("quote.subtotal") + ": " + money(quote.totals.preTax))
                paragraph(l("project.tax") + ": " + money(quote.totals.tax))
                paragraph(l("project.total") + ": " + money(quote.totals.total), font: .boldSystemFont(ofSize: 13))
                if !quote.includeBranding && !quote.terms.isEmpty {
                    paragraph(l("project.terms"), font: .boldSystemFont(ofSize: 11))
                    paragraph(quote.terms)
                }
            }
        } catch { throw QuoteExportError.unableToWrite }
        return url
    }
}
