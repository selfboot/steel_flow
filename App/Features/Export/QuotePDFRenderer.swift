import Foundation
import UIKit

/// Renders frozen values only, including repeatable dates, units and branding.
@MainActor
enum QuotePDFRenderer {
    static func render(_ quote: QuoteSnapshotPayload) throws -> URL {
        let size = quote.paperSize == PaperSize.letter.rawValue ? CGSize(width: 612, height: 792) : CGSize(width: 595.2, height: 841.8)
        let style = quote.quoteStyle
        let styled = style != .classic
        let palette = QuoteStylePalette(style)
        let locale = Locale(identifier: quote.quoteLanguage)
        let system = UnitSystem(rawValue: quote.unitSystemRaw ?? "") ?? .metric
        let margin: CGFloat = 36, contentWidth = size.width - 72
        let bodyFont = UIFont.systemFont(ofSize: styled ? 9.5 : 9)
        let headerFont = UIFont.systemFont(ofSize: 9, weight: styled ? .semibold : .regular)
        let lineHeight: CGFloat = styled && style != .ledger ? 14 : 13
        let bottom = size.height - 55
        let showMass = quote.showMass ?? true
        let showUnitPrice = quote.showUnitPrice ?? false
        func l(_ key: String) -> String { AppLocalization.text(key, locale: locale) }
        func money(_ value: Decimal) -> String { AppFormatters.decimal(value, currencyCode: quote.currencyCode, locale: locale) }
        let filePrefix = quote.includeBranding ? "SteelFlow" : "Quote"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)_\(quote.projectNumber.filter { $0.isLetter || $0.isNumber || $0 == "-" }.prefix(50))_\(UUID().uuidString.prefix(8)).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        var y: CGFloat = 36
        var page = 0
        func draw(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont = .systemFont(ofSize: 9), color: UIColor = .black, alignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping) {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            paragraph.lineBreakMode = lineBreakMode
            (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: max(16, font.lineHeight + 2)), withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
        }
        // Prefer word boundaries, with glyph wrapping for unbroken part numbers and CJK text.
        func wrap(_ text: String, width: CGFloat, font: UIFont = .systemFont(ofSize: 9)) -> [String] {
            var result: [String] = []
            for paragraph in text.components(separatedBy: "\n") {
                var line = ""
                for character in paragraph {
                    // Recheck the remainder: dropping a short prefix may still leave
                    // an overwide word, which needs a second (glyph) split.
                    while !line.isEmpty && ((line + String(character)) as NSString).size(withAttributes: [.font: font]).width > width {
                        if let space = line.lastIndex(where: { $0 == " " || $0 == "\t" }), space != line.startIndex {
                            result.append(String(line[..<space]))
                            line = String(line[line.index(after: space)...])
                        } else {
                            result.append(line); line = ""
                        }
                    }
                    line.append(character)
                }
                result.append(line)
            }
            return result
        }
        let quantityWidth = max(30, ceil((l("quote.quantity") as NSString).size(withAttributes: [.font: bodyFont]).width) + 8)
        let amountFont = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .medium)
        let measuredAmountWidth = quote.lines.map { ceil((money($0.customerQuoteAmount) as NSString).size(withAttributes: [.font: amountFont]).width) + 8 }.max() ?? 84
        let amountWidth = styled ? min(contentWidth * 0.30, max(84, measuredAmountWidth)) : 84
        var widths: [CGFloat] = [contentWidth - quantityWidth - amountWidth, quantityWidth, amountWidth]
        var headers = [l("quote.item"), l("quote.quantity"), l("quote.amount")]
        if showMass { widths[0] -= 68; widths.insert(68, at: widths.count - 1); headers.insert(l("quote.mass"), at: headers.count - 1) }
        if showUnitPrice { widths[0] -= 85; widths.insert(85, at: widths.count - 1); headers.insert(l("workflow.sales_unit_price"), at: headers.count - 1) }
        do {
            try renderer.writePDF(to: url) { context in
                @MainActor func ledgerColumns(at top: CGFloat, height: CGFloat) {
                    guard style == .ledger else { return }
                    palette.rule.setFill()
                    var x = margin
                    for width in widths {
                        context.cgContext.fill(CGRect(x: x, y: top, width: 0.5, height: height))
                        x += width
                    }
                    context.cgContext.fill(CGRect(x: x - 0.5, y: top, width: 0.5, height: height))
                }
                @MainActor func tableHeader() {
                    let wrappedHeaders = headers.indices.map { wrap(headers[$0], width: widths[$0] - 8, font: headerFont) }
                    let height = max(28, CGFloat(wrappedHeaders.map(\.count).max() ?? 1) * 12 + (styled ? 14 : 4))
                    palette.wash.setFill()
                    context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: height))
                    if style == .executive || style == .ledger {
                        palette.accent.setFill()
                        context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 0.7))
                        context.cgContext.fill(CGRect(x: margin, y: y + height - 0.5, width: contentWidth, height: 0.5))
                    }
                    ledgerColumns(at: y, height: height)
                    var x = margin
                    for i in headers.indices {
                        for (j, text) in wrappedHeaders[i].enumerated() {
                            draw(text, x: x + 4, y: y + (styled ? 7 : 2) + CGFloat(j) * 12, width: widths[i] - 8, font: headerFont, color: styled ? palette.accent : palette.ink, alignment: styled && i > 0 ? .right : .left)
                        }
                        x += widths[i]
                    }
                    y += height + (style == .ledger ? 0 : 2)
                }
                @MainActor func newPage(table: Bool = false) {
                    context.beginPage(); page += 1; y = margin
                    draw(String(page), x: size.width - 60, y: size.height - 38, width: 25)
                    if styled {
                        palette.rule.setFill()
                        context.cgContext.fill(CGRect(x: margin, y: size.height - 47, width: contentWidth, height: 0.5))
                    }
                    if page > 1 {
                        draw(l("quote.title") + " · " + quote.projectNumber, x: margin, y: y, width: contentWidth, lineBreakMode: .byTruncatingMiddle)
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
                @MainActor func rule(_ color: UIColor, height: CGFloat = 1) {
                    color.setFill()
                    context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: height))
                    y += height + 16
                }
                typealias TextLine = (text: String, font: UIFont, color: UIColor)
                @MainActor func textLines(_ text: String, width: CGFloat, font: UIFont, color: UIColor) -> [TextLine] {
                    wrap(text, width: width, font: font).map { ($0, font, color) }
                }
                @MainActor func columns(_ left: [TextLine], _ right: [TextLine], leftWidth: CGFloat, gap: CGFloat) {
                    let rightWidth = contentWidth - leftWidth - gap
                    for row in 0..<max(left.count, right.count) {
                        let height = max(row < left.count ? ceil(left[row].font.lineHeight) : 0,
                                         row < right.count ? ceil(right[row].font.lineHeight) : 0) + 5
                        if y + height > bottom { newPage() }
                        if row < left.count {
                            let line = left[row]
                            draw(line.text, x: margin, y: y, width: leftWidth, font: line.font, color: line.color)
                        }
                        if row < right.count {
                            let line = right[row]
                            draw(line.text, x: margin + leftWidth + gap, y: y, width: rightWidth,
                                 font: line.font, color: line.color, alignment: .right)
                        }
                        y += height
                    }
                }
                @MainActor func headingLines(_ lines: [TextLine], alignment: NSTextAlignment = .left) {
                    for line in lines {
                        let height = ceil(line.font.lineHeight) + 5
                        if y + height > bottom { newPage() }
                        draw(line.text, x: margin, y: y, width: contentWidth, font: line.font, color: line.color, alignment: alignment)
                        y += height
                    }
                }
                @MainActor func companyLines(width: CGFloat, font: UIFont) -> [TextLine] {
                    let name = quote.company?.companyName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let companyName = name.isEmpty ? (quote.includeBranding ? "SteelFlow" : "") : name
                    var lines = companyName.isEmpty ? [] : textLines(companyName, width: width, font: font, color: palette.accent)
                    if let company = quote.company {
                        for detail in [company.contactName, company.phone, company.email, company.address] where !detail.isEmpty {
                            lines += textLines(detail, width: width, font: .systemFont(ofSize: 9), color: palette.secondary)
                        }
                    }
                    return lines
                }
                @MainActor func styledTitle() {
                    let gap: CGFloat = 28, leftWidth = contentWidth * 0.56
                    let rightWidth = contentWidth - leftWidth - gap
                    if let data = quote.company?.logoData, let image = UIImage(data: data) {
                        let scale = min(100 / image.size.width, 42 / image.size.height)
                        image.draw(in: CGRect(x: style == .executive ? (size.width - image.size.width * scale) / 2 : margin, y: y, width: image.size.width * scale, height: image.size.height * scale))
                        y += 54
                    }
                    if style == .executive {
                        let descriptor = UIFont.systemFont(ofSize: 20, weight: .semibold).fontDescriptor
                        let formalFont = UIFont(descriptor: descriptor.withDesign(.serif) ?? descriptor, size: 20)
                        let company = companyLines(width: contentWidth, font: formalFont)
                        headingLines(company, alignment: .center)
                        if !company.isEmpty { y += 12 }
                        if y + 24 > bottom { newPage() }
                        palette.accent.setFill()
                        context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 1))
                        context.cgContext.fill(CGRect(x: margin, y: y + 4, width: contentWidth, height: 0.5))
                        y += 22
                        headingLines(textLines(l("quote.title"), width: contentWidth, font: .systemFont(ofSize: 25, weight: .medium), color: palette.accent), alignment: .center)
                        headingLines(textLines(quote.projectNumber, width: contentWidth, font: .systemFont(ofSize: 9), color: palette.secondary), alignment: .center)
                        y += 20
                        return
                    }
                    if style == .modern {
                        palette.accent.setFill()
                        context.cgContext.fill(CGRect(x: margin - 10, y: y + 2, width: 3, height: 56))
                        let title = textLines(l("quote.title"), width: leftWidth, font: .systemFont(ofSize: 32, weight: .bold), color: palette.ink)
                            + textLines(quote.projectNumber, width: leftWidth, font: .systemFont(ofSize: 10), color: palette.secondary)
                        columns(title, companyLines(width: rightWidth, font: .systemFont(ofSize: 13, weight: .semibold)), leftWidth: leftWidth, gap: gap)
                        y += 24
                        return
                    }
                    if style == .ledger {
                        columns(textLines(l("quote.title"), width: leftWidth, font: .systemFont(ofSize: 20, weight: .bold), color: palette.accent),
                                textLines(quote.projectNumber, width: rightWidth, font: .monospacedDigitSystemFont(ofSize: 9, weight: .regular), color: palette.secondary), leftWidth: leftWidth, gap: gap)
                        y += 10
                        if y + 20 > bottom { newPage() }
                        rule(palette.accent, height: 1)
                        headingLines(companyLines(width: contentWidth, font: .systemFont(ofSize: 15, weight: .semibold)))
                        y += 8
                        return
                    }
                    let left = companyLines(width: leftWidth, font: .systemFont(ofSize: 18, weight: .bold))
                    let right = textLines(l("quote.title"), width: rightWidth, font: .systemFont(ofSize: 25, weight: .bold), color: palette.accent)
                        + textLines(quote.projectNumber, width: rightWidth, font: .systemFont(ofSize: 9), color: palette.secondary)
                    columns(left, right, leftWidth: leftWidth, gap: gap)
                    y += 16
                    if y + 20 > bottom { newPage() }
                    rule(palette.accent, height: style == .minimal ? 0.8 : 1.5)
                }
                @MainActor func customerDetails() {
                    let gap: CGFloat = 28, column = (contentWidth - gap) / 2
                    let left = textLines(l("project.customer"), width: column, font: .systemFont(ofSize: 9, weight: .semibold), color: palette.accent)
                        + textLines(quote.customerName.isEmpty ? "—" : quote.customerName, width: column, font: .systemFont(ofSize: 11, weight: .medium), color: palette.ink)
                        + ((quote.customerContact ?? "").isEmpty ? [] : textLines(quote.customerContact ?? "", width: column, font: .systemFont(ofSize: 9), color: palette.secondary))
                    let right = [l("quote.issued_on") + "  " + AppFormatters.date(quote.generatedAt, locale: locale),
                                 l("quote.valid_until") + "  " + AppFormatters.date(quote.validUntil, locale: locale)]
                        .flatMap { textLines($0, width: column, font: .systemFont(ofSize: 9), color: palette.ink) }
                    if y + 65 > bottom { newPage() }
                    y += 4
                    columns(left, right, leftWidth: column, gap: gap)
                    y += 24
                }
                @MainActor func styledTotals() {
                    let totalWidth = style == .modern ? contentWidth : contentWidth * (style == .ledger ? 0.68 : 0.62)
                    let topGap: CGFloat = style == .ledger ? 28 : 18
                    let rowGap: CGFloat = style == .ledger ? 12 : 6
                    let totalInset: CGFloat = style == .ledger ? 18 : 12
                    let x = margin + contentWidth - totalWidth
                    let rows = [(l("quote.subtotal"), money(quote.totals.preTax)), (l("project.tax"), money(quote.totals.tax)), (l("project.total"), money(quote.totals.total))]
                    let rowLayouts = rows.enumerated().map { index, pair in
                        let font = UIFont.monospacedDigitSystemFont(ofSize: index == 2 ? (style == .modern ? 23 : 16) : 10, weight: index == 2 ? .bold : .regular)
                        // Give large monetary values more room while keeping a real gap to labels.
                        let valueWidth = min(totalWidth * 0.70, max(totalWidth * 0.52, ceil((pair.1 as NSString).size(withAttributes: [.font: font]).width)))
                        let labelWidth = totalWidth - valueWidth - 20
                        let labels = wrap(pair.0, width: labelWidth, font: font)
                        let values = wrap(pair.1, width: valueWidth, font: font)
                        return (font, valueWidth, labelWidth, labels, values)
                    }
                    let height = rowLayouts.enumerated().reduce(topGap) { result, entry in
                        let (_, _, _, labels, values) = entry.element
                        return result + CGFloat(max(labels.count, values.count)) * (ceil(entry.element.0.lineHeight) + 4) + (entry.offset == 2 ? totalInset : rowGap)
                    }
                    if height < bottom - margin - 24 && y + height > bottom { newPage() }
                    y += topGap
                    for (index, layout) in rowLayouts.enumerated() {
                        let (font, valueWidth, labelWidth, labels, values) = layout
                        let rowHeight = ceil(font.lineHeight) + 4
                        if index == 2 {
                            if y + rowHeight + totalInset > bottom { newPage() }
                            palette.accent.setFill()
                            context.cgContext.fill(CGRect(x: x, y: y, width: totalWidth, height: 0.8))
                            y += totalInset
                        }
                        for row in 0..<max(labels.count, values.count) {
                            if y + rowHeight > bottom { newPage() }
                            let color = index == 2 ? palette.accent : palette.ink
                            if row < labels.count { draw(labels[row], x: x, y: y, width: labelWidth, font: font, color: color) }
                            if row < values.count { draw(values[row], x: margin + contentWidth - valueWidth - 4, y: y, width: valueWidth, font: font, color: color, alignment: .right) }
                            y += rowHeight
                        }
                        y += rowGap
                    }
                    y += 22
                }
                newPage()
                if styled { styledTitle() } else {
                if let data = quote.company?.logoData, let image = UIImage(data: data) {
                    if y + 54 > bottom { newPage() }
                    let scale = min(100 / image.size.width, 48 / image.size.height)
                    image.draw(in: CGRect(x: margin, y: y, width: image.size.width * scale, height: image.size.height * scale)); y += 54
                }
                if let companyName = quote.company?.companyName,
                   !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    paragraph(companyName, font: .boldSystemFont(ofSize: 18))
                } else if quote.includeBranding {
                    paragraph("SteelFlow", font: .boldSystemFont(ofSize: 18))
                }
                if let company = quote.company {
                    let details = [company.contactName, company.phone, company.email, company.address].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !details.isEmpty { paragraph(details, font: .systemFont(ofSize: 9)) }
                }
                }
                if styled { customerDetails() } else {
                paragraph(l("quote.title") + " · " + quote.projectNumber, font: .boldSystemFont(ofSize: 16))
                paragraph(l("project.customer") + ": " + (quote.customerName.isEmpty ? "—" : quote.customerName))
                if let contact = quote.customerContact, !contact.isEmpty { paragraph(contact) }
                paragraph(AppFormatters.date(quote.generatedAt, locale: locale) + " · " + l("quote.valid_until") + ": " + AppFormatters.date(quote.validUntil, locale: locale))
                }
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
                    let lines: [[TextLine]] = cells.enumerated().map { col, cell in
                        if styled && col == 0 {
                            return cell.components(separatedBy: "\n").enumerated().flatMap { part, text in
                                textLines(text, width: widths[col] - 8,
                                          font: .systemFont(ofSize: part == 0 ? 9.5 : 9, weight: part == 0 ? .semibold : .regular),
                                          color: part == 0 ? palette.ink : palette.secondary)
                            }
                        }
                        return textLines(cell, width: widths[col] - 8,
                                         font: styled ? .monospacedDigitSystemFont(ofSize: 9.5, weight: col == cells.count - 1 ? .medium : .regular) : bodyFont,
                                         color: palette.ink)
                    }
                    let count = lines.map(\.count).max() ?? 1
                    let topPadding: CGFloat = style == .ledger ? 5 : styled ? 8 : 0
                    let bottomPadding: CGFloat = style == .ledger ? 7 : styled ? 12 : 8
                    let padding = topPadding + bottomPadding
                    if styled && CGFloat(count) * lineHeight + padding < bottom - margin - 70 && y + CGFloat(count) * lineHeight + padding > bottom { newPage(table: true) }
                    ledgerColumns(at: y, height: topPadding)
                    y += topPadding
                    for row in 0..<count {
                        if y + lineHeight + bottomPadding > bottom {
                            if style == .ledger {
                                palette.rule.setFill()
                                context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 0.5))
                            }
                            newPage(table: true)
                            ledgerColumns(at: y, height: topPadding); y += topPadding
                        }
                        ledgerColumns(at: y, height: lineHeight)
                        var x = margin
                        for col in lines.indices {
                            if row < lines[col].count {
                                let line = lines[col][row]
                                draw(line.text, x: x + 4, y: y, width: widths[col] - 8, font: line.font, color: line.color, alignment: styled && col > 0 ? .right : .left)
                            }
                            x += widths[col]
                        }
                        y += lineHeight
                    }
                    ledgerColumns(at: y, height: bottomPadding)
                    y += bottomPadding
                    (styled ? palette.rule : UIColor(white: 0.8, alpha: 1)).setFill()
                    context.cgContext.fill(CGRect(x: margin, y: y - (style == .ledger ? 0.5 : 4), width: contentWidth, height: 0.5))
                }
                if !styled && y + 85 > bottom { newPage() }
                if styled { styledTotals() } else {
                y += 8
                paragraph(l("quote.subtotal") + ": " + money(quote.totals.preTax))
                paragraph(l("project.tax") + ": " + money(quote.totals.tax))
                paragraph(l("project.total") + ": " + money(quote.totals.total), font: .boldSystemFont(ofSize: 13))
                }
            }
        } catch { throw QuoteExportError.unableToWrite }
        return url
    }
}
