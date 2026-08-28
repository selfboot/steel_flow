import Foundation
import UIKit

enum QuoteExportError: LocalizedError, Equatable {
    case noValidItems
    case invalidPricing
    case unableToWrite

    var errorDescription: String? {
        switch self {
        case .noValidItems: AppLocalization.text("export.error.no_valid_items")
        case .invalidPricing: AppLocalization.text("export.error.invalid_pricing")
        case .unableToWrite: AppLocalization.text("export.error.write")
        }
    }
}

enum QuotePaginator {
    static let contentStartY: CGFloat = 167
    static let rowHeight: CGFloat = 38
    static let footerClearance: CGFloat = 56
    static let totalsReservation: CGFloat = 117

    static func pageRowCounts(itemCount: Int, pageHeight: CGFloat) -> [Int] {
        guard itemCount > 0 else { return [] }
        let usableBottom = pageHeight - footerClearance
        let regularCapacity = max(1, Int(floor((usableBottom - contentStartY) / rowHeight)))
        let finalCapacity = max(1, Int(floor((usableBottom - contentStartY - totalsReservation) / rowHeight)))
        var remaining = itemCount
        var pages: [Int] = []
        while remaining > finalCapacity {
            let count = remaining <= regularCapacity ? finalCapacity : regularCapacity
            pages.append(count)
            remaining -= count
        }
        if remaining > 0 { pages.append(remaining) }
        return pages
    }
}

struct QuoteSnapshotPayload: Codable, Sendable {
    struct Company: Codable, Sendable {
        let companyName: String
        let contactName: String
        let email: String
        let phone: String
        let address: String
    }

    struct Line: Codable, Sendable {
        let itemID: UUID
        let profile: String
        let geometry: GeometryInput
        let materialID: String
        let materialName: String
        let materialGrade: String
        let densityKgPerM3: Double
        let lengthValue: Double
        let lengthUnit: String
        let quantity: Int
        let wastePercent: Double
        let areaSquareMeters: Double
        let volumeCubicMeters: Double
        let unitMassKg: Double
        let totalMassKg: Double
        let wasteAdjustedMassKg: Double
        let priceBasis: String
        let unitPrice: Decimal
        let processingFee: Decimal
        let otherFee: Decimal
        let materialSubtotal: Decimal
        let customerQuoteAmount: Decimal
        let priceSource: String
        let priceSourceName: String
        let priceRegion: String
        let priceIncludesTax: Bool
        let priceEffectiveAt: Date?
        let descriptionText: String
        let internalNote: String
    }

    struct Totals: Codable, Sendable {
        let materialSubtotal: Decimal
        let fees: Decimal
        let profit: Decimal
        let preTax: Decimal
        let tax: Decimal
        let total: Decimal
    }

    let schemaVersion: Int
    let generatedAt: Date
    let validUntil: Date
    let engineVersion: Int
    let projectID: UUID
    let projectName: String
    let projectNumber: String
    let customerName: String
    let quoteLanguage: String
    let currencyCode: String
    let paperSize: String
    let includeBranding: Bool
    let company: Company?
    let profitMode: String
    let profitPercent: Decimal
    let taxPercent: Decimal
    let terms: String
    let lines: [Line]
    let totals: Totals
}

@MainActor
enum QuoteExportService {
    private static let pdfText = UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1)
    private static let pdfSecondary = UIColor(red: 0.34, green: 0.38, blue: 0.42, alpha: 1)
    private static let pdfAccent = UIColor(red: 0.04, green: 0.43, blue: 0.62, alpha: 1)
    private static let pdfHeader = UIColor(red: 0.03, green: 0.20, blue: 0.27, alpha: 1)
    private static let pdfRowFill = UIColor(white: 0.96, alpha: 1)
    private static let pdfSeparator = UIColor(white: 0.78, alpha: 1)

    static func snapshotData(
        for project: ProjectEntity,
        company: CompanyProfileEntity? = nil,
        generatedAt: Date = .now,
        includeBranding: Bool = true
    ) throws -> Data {
        let summary = ProjectCalculator.summarize(project)
        guard !summary.lines.isEmpty else { throw QuoteExportError.noValidItems }
        guard summary.invalidItemCount == 0, summary.isPricingPolicyValid else { throw QuoteExportError.invalidPricing }
        let locale = Locale(identifier: project.quoteLanguage)
        let payload = QuoteSnapshotPayload(
            schemaVersion: 3,
            generatedAt: generatedAt,
            validUntil: Calendar.current.date(byAdding: .day, value: project.validDays, to: generatedAt) ?? generatedAt,
            engineVersion: CalculationEngine.version,
            projectID: project.id,
            projectName: project.name,
            projectNumber: project.projectNumber,
            customerName: project.customerName,
            quoteLanguage: project.quoteLanguage,
            currencyCode: project.currencyCode,
            paperSize: project.paperSize.rawValue,
            includeBranding: includeBranding,
            company: company.map {
                .init(companyName: $0.companyName, contactName: $0.contactName, email: $0.email, phone: $0.phone, address: $0.address)
            },
            profitMode: project.profitMode.rawValue,
            profitPercent: project.markupPercent,
            taxPercent: project.taxPercent,
            terms: project.terms,
            lines: summary.lines.map { line in
                let item = line.item
                return .init(
                    itemID: item.id,
                    profile: item.profile.rawValue,
                    geometry: item.geometry,
                    materialID: item.materialID,
                    materialName: MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale),
                    materialGrade: item.materialGrade,
                    densityKgPerM3: item.densityKgPerM3,
                    lengthValue: item.lengthValue,
                    lengthUnit: item.lengthUnit.rawValue,
                    quantity: item.quantity,
                    wastePercent: item.wastePercent,
                    areaSquareMeters: line.result.areaSquareMeters,
                    volumeCubicMeters: line.result.volumeCubicMeters,
                    unitMassKg: line.result.unitMassKg,
                    totalMassKg: line.result.totalMassKg,
                    wasteAdjustedMassKg: line.result.wasteAdjustedMassKg,
                    priceBasis: item.priceBasis.rawValue,
                    unitPrice: item.unitPrice,
                    processingFee: CurrencyRules.round(item.processingFee, currencyCode: project.currencyCode),
                    otherFee: CurrencyRules.round(item.otherFee, currencyCode: project.currencyCode),
                    materialSubtotal: line.materialSubtotal,
                    customerQuoteAmount: line.customerQuoteAmount,
                    priceSource: item.priceSource.rawValue,
                    priceSourceName: item.priceSourceName,
                    priceRegion: item.priceRegion,
                    priceIncludesTax: item.priceIncludesTax,
                    priceEffectiveAt: item.priceEffectiveAt,
                    descriptionText: item.descriptionText,
                    internalNote: item.internalNote
                )
            },
            totals: .init(
                materialSubtotal: summary.pricing.materialSubtotal,
                fees: summary.pricing.fees,
                profit: summary.pricing.profit,
                preTax: summary.pricing.preTax,
                tax: summary.pricing.tax,
                total: summary.pricing.total
            )
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func csvURL(for project: ProjectEntity, includeBOM: Bool = true, generatedAt: Date = .now) throws -> URL {
        let summary = ProjectCalculator.summarize(project)
        guard !summary.lines.isEmpty else { throw QuoteExportError.noValidItems }
        guard summary.invalidItemCount == 0, summary.isPricingPolicyValid else { throw QuoteExportError.invalidPricing }
        let locale = Locale(identifier: project.quoteLanguage)
        let header = "row_type,item_id,profile_kind,description,material,material_id,material_grade,density_kg_m3,length_value,length_unit,quantity,area_m2,volume_m3,unit_mass_kg,total_mass_kg,waste_percent,waste_adjusted_mass_kg,unit_price,price_basis,currency,material_subtotal,processing_fee,other_fee,price_source,price_source_name,price_region,price_effective_date,price_includes_tax,project_profit,project_tax,project_total"
        var rows = [header]
        for line in summary.lines {
            let item = line.item
            rows.append([
                "item",
                item.id.uuidString,
                item.profile.rawValue,
                csvCell(item.descriptionText),
                csvCell(MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale)),
                csvCell(item.materialID),
                csvCell(item.materialGrade),
                machine(item.densityKgPerM3),
                machine(item.lengthValue),
                item.lengthUnit.rawValue,
                String(item.quantity),
                machine(line.result.areaSquareMeters),
                machine(line.result.volumeCubicMeters),
                machine(line.result.unitMassKg),
                machine(line.result.totalMassKg),
                machine(item.wastePercent),
                machine(line.result.wasteAdjustedMassKg),
                item.unitPrice.description,
                item.priceBasis.rawValue,
                project.currencyCode,
                line.materialSubtotal.description,
                CurrencyRules.round(item.processingFee, currencyCode: project.currencyCode).description,
                CurrencyRules.round(item.otherFee, currencyCode: project.currencyCode).description,
                item.priceSource.rawValue,
                csvCell(item.priceSourceName),
                csvCell(item.priceRegion),
                item.priceEffectiveAt.map(iso8601) ?? "",
                item.priceIncludesTax ? "true" : "false",
                "", "", ""
            ].joined(separator: ","))
        }
        let processing = summary.lines.reduce(Decimal.zero) { $0 + CurrencyRules.round($1.item.processingFee, currencyCode: project.currencyCode) }
        let other = summary.lines.reduce(Decimal.zero) { $0 + CurrencyRules.round($1.item.otherFee, currencyCode: project.currencyCode) }
        rows.append([
            "project_summary", "", "", csvCell(project.name), "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", project.currencyCode,
            summary.pricing.materialSubtotal.description, processing.description, other.description, "", "", "", iso8601(generatedAt), "",
            summary.pricing.profit.description, summary.pricing.tax.description, summary.pricing.total.description
        ].joined(separator: ","))
        let content = (includeBOM ? "\u{FEFF}" : "") + rows.joined(separator: "\r\n") + "\r\n"
        let url = temporaryURL(project: project, extension: "csv")
        do { try content.write(to: url, atomically: true, encoding: .utf8) }
        catch { throw QuoteExportError.unableToWrite }
        return url
    }

    static func pdfURL(for project: ProjectEntity, company: CompanyProfileEntity?, generatedAt: Date = .now, includeBranding: Bool = true) throws -> URL {
        let summary = ProjectCalculator.summarize(project)
        guard !summary.lines.isEmpty else { throw QuoteExportError.noValidItems }
        guard summary.invalidItemCount == 0, summary.isPricingPolicyValid else { throw QuoteExportError.invalidPricing }
        let pageSize = project.paperSize == .a4 ? CGSize(width: 595.2, height: 841.8) : CGSize(width: 612, height: 792)
        let bounds = CGRect(origin: .zero, size: pageSize)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(localized("quote.title", language: project.quoteLanguage)) \(project.projectNumber)",
            kCGPDFContextCreator as String: "SteelFlow"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        let url = temporaryURL(project: project, extension: "pdf")

        do {
            try renderer.writePDF(to: url) { context in
                var lineIndex = 0
                let pageCounts = QuotePaginator.pageRowCounts(itemCount: summary.lines.count, pageHeight: bounds.height)
                for (pageOffset, rowCount) in pageCounts.enumerated() {
                    context.beginPage()
                    let page = pageOffset + 1
                    var y = drawHeader(project: project, company: company, page: page, bounds: bounds, generatedAt: generatedAt)
                    y = drawTableHeader(language: project.quoteLanguage, y: y, bounds: bounds)
                    for _ in 0..<rowCount {
                        y = draw(line: summary.lines[lineIndex], project: project, index: lineIndex + 1, y: y, bounds: bounds)
                        lineIndex += 1
                    }
                    if pageOffset == pageCounts.count - 1 {
                        drawTotals(summary: summary, project: project, y: y + 12, bounds: bounds, includeCustomTerms: !includeBranding)
                    }
                        drawFooter(page: page, language: project.quoteLanguage, bounds: bounds, includeBranding: includeBranding)
                }
            }
        } catch {
            throw QuoteExportError.unableToWrite
        }
        return url
    }

    private static func drawHeader(project: ProjectEntity, company: CompanyProfileEntity?, page: Int, bounds: CGRect, generatedAt: Date) -> CGFloat {
        let margin: CGFloat = 36
        var y: CGFloat = 34
        let companyName = company.flatMap { $0.companyName.isEmpty ? nil : $0.companyName } ?? "SteelFlow"
        let hasCompanyDetails = company.map { !$0.contactName.isEmpty || !$0.email.isEmpty || !$0.phone.isEmpty || !$0.address.isEmpty } ?? false
        let companyNameWidth = hasCompanyDetails ? bounds.width / 2 - margin - 8 : bounds.width - margin * 2
        drawText(companyName, frame: CGRect(x: margin, y: y, width: companyNameWidth, height: 28), font: .systemFont(ofSize: 20, weight: .bold), color: pdfText)
        if let company {
            let contacts = [company.contactName, company.email, company.phone].filter { !$0.isEmpty }.joined(separator: " · ")
            if !contacts.isEmpty {
                drawText(contacts, frame: CGRect(x: bounds.width / 2, y: y, width: bounds.width / 2 - margin, height: 14), font: .systemFont(ofSize: 8.5), color: pdfSecondary, alignment: .right)
            }
            if !company.address.isEmpty {
                drawText(company.address, frame: CGRect(x: bounds.width / 2, y: y + 14, width: bounds.width / 2 - margin, height: 14), font: .systemFont(ofSize: 8.5), color: pdfSecondary, alignment: .right)
            }
        }
        y += 31
        drawText(localized("quote.title", language: project.quoteLanguage), frame: CGRect(x: margin, y: y, width: 250, height: 32), font: .systemFont(ofSize: 26, weight: .bold), color: pdfAccent)
        drawText(project.projectNumber, frame: CGRect(x: bounds.width - margin - 180, y: y + 5, width: 180, height: 24), font: .monospacedSystemFont(ofSize: 12, weight: .medium), color: pdfSecondary, alignment: .right)
        y += 40
        drawText("\(localized("project.customer", language: project.quoteLanguage)): \(project.customerName.isEmpty ? "—" : project.customerName)", frame: CGRect(x: margin, y: y, width: 280, height: 22), font: .systemFont(ofSize: 11), color: pdfText)
        let validity = Calendar.current.date(byAdding: .day, value: project.validDays, to: generatedAt) ?? generatedAt
        drawText("\(localized("quote.valid_until", language: project.quoteLanguage)): \(AppFormatters.date(validity, locale: Locale(identifier: project.quoteLanguage)))", frame: CGRect(x: bounds.width - margin - 240, y: y, width: 240, height: 22), font: .systemFont(ofSize: 11), color: pdfText, alignment: .right)
        y += 34
        return y
    }

    private static func drawTableHeader(language: String, y: CGFloat, bounds: CGRect) -> CGFloat {
        let margin: CGFloat = 36
        let widths: [CGFloat] = [28, 150, 72, 50, 74, 90]
        let labels = ["#", localized("quote.item", language: language), localized("quote.material", language: language), localized("quote.quantity", language: language), localized("quote.mass", language: language), localized("quote.amount", language: language)]
        pdfHeader.setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 28), cornerRadius: 4).fill()
        var x = margin + 4
        for (index, label) in labels.enumerated() {
            drawText(label, frame: CGRect(x: x, y: y + 6, width: widths[index] - 6, height: 16), font: .systemFont(ofSize: 9, weight: .semibold), color: .white, alignment: index >= 3 ? .right : .left)
            x += widths[index]
        }
        return y + 28
    }

    private static func draw(line: ProjectLineSummary, project: ProjectEntity, index: Int, y: CGFloat, bounds: CGRect) -> CGFloat {
        let margin: CGFloat = 36
        let widths: [CGFloat] = [28, 150, 72, 50, 74, 90]
        let rowHeight = QuotePaginator.rowHeight
        if index.isMultiple(of: 2) {
            pdfRowFill.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: rowHeight)).fill()
        }
        let item = line.item
        let description = item.descriptionText.isEmpty ? localized("profile.\(item.profile.rawValue)", language: project.quoteLanguage) : item.descriptionText
        let values = [
            String(index),
            description + "\n" + dimensionsSummary(item, language: project.quoteLanguage),
            MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: Locale(identifier: project.quoteLanguage)),
            String(item.quantity),
            AppFormatters.number(line.result.totalMassKg, maximumFractionDigits: 2, locale: Locale(identifier: project.quoteLanguage)) + " kg",
            AppFormatters.decimal(line.customerQuoteAmount, currencyCode: project.currencyCode, locale: Locale(identifier: project.quoteLanguage))
        ]
        var x = margin + 4
        for (column, value) in values.enumerated() {
            drawText(value, frame: CGRect(x: x, y: y + 5, width: widths[column] - 6, height: rowHeight - 8), font: .systemFont(ofSize: column == 1 ? 8.5 : 9), color: pdfText, alignment: column >= 3 ? .right : .left)
            x += widths[column]
        }
        pdfSeparator.setStroke()
        let path = UIBezierPath(); path.move(to: CGPoint(x: margin, y: y + rowHeight)); path.addLine(to: CGPoint(x: bounds.width - margin, y: y + rowHeight)); path.lineWidth = 0.4; path.stroke()
        return y + rowHeight
    }

    private static func drawTotals(summary: ProjectSummary, project: ProjectEntity, y: CGFloat, bounds: CGRect, includeCustomTerms: Bool) {
        let labelX = bounds.width - 340
        let amountX = bounds.width - 36 - 110
        var cursor = y
        let locale = Locale(identifier: project.quoteLanguage)
        let rows: [(String, Decimal, Bool)] = [
            (localized("quote.subtotal", language: project.quoteLanguage), summary.pricing.preTax, false),
            (localized("project.tax", language: project.quoteLanguage), summary.pricing.tax, false),
            (localized("project.total", language: project.quoteLanguage), summary.pricing.total, true)
        ]
        for row in rows {
            drawText(row.0, frame: CGRect(x: labelX, y: cursor, width: amountX - labelX - 10, height: 20), font: .systemFont(ofSize: row.2 ? 12 : 10, weight: row.2 ? .bold : .regular), color: pdfText, alignment: .right)
            drawText(AppFormatters.decimal(row.1, currencyCode: project.currencyCode, locale: locale), frame: CGRect(x: amountX, y: cursor, width: 110, height: 20), font: .monospacedSystemFont(ofSize: row.2 ? 12 : 10, weight: row.2 ? .bold : .regular), color: row.2 ? pdfAccent : pdfText, alignment: .right)
            cursor += 21
        }
        if includeCustomTerms, !project.terms.isEmpty {
            drawText("\(localized("project.terms", language: project.quoteLanguage)): \(project.terms)", frame: CGRect(x: 36, y: y, width: labelX - 52, height: 90), font: .systemFont(ofSize: 9), color: pdfSecondary)
        }
    }

    private static func drawFooter(page: Int, language: String, bounds: CGRect, includeBranding: Bool) {
        let footer = includeBranding
            ? "\(localized("quote.generated_by", language: language)) · \(localized("quote.disclaimer", language: language))"
            : localized("quote.disclaimer", language: language)
        drawText(footer, frame: CGRect(x: 36, y: bounds.height - 38, width: bounds.width - 120, height: 18), font: .systemFont(ofSize: 7.5), color: pdfSecondary)
        drawText(String(page), frame: CGRect(x: bounds.width - 70, y: bounds.height - 38, width: 34, height: 18), font: .monospacedSystemFont(ofSize: 8, weight: .regular), color: pdfSecondary, alignment: .right)
    }

    private static func drawText(_ text: String, frame: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle(); style.alignment = alignment; style.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(with: frame, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style], context: nil)
    }

    private static func localized(_ key: String, language: String) -> String {
        AppLocalization.text(key, locale: Locale(identifier: language))
    }

    private static func dimensionsSummary(_ item: CalculationItemEntity, language: String) -> String {
        let locale = Locale(identifier: language)
        return item.profile.dimensionFields.compactMap { field in
            item.geometry.values[field].map { "\(AppFormatters.number($0, locale: locale)) \(field == .customArea ? item.geometry.areaUnit.rawValue : item.geometry.lengthUnit.rawValue)" }
        }.joined(separator: " × ")
    }

    private static func machine(_ value: Double) -> String { String(format: "%.10g", locale: Locale(identifier: "en_US_POSIX"), value) }
    private static func iso8601(_ value: Date) -> String { ISO8601DateFormatter().string(from: value) }
    private static func csvCell(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
    private static func temporaryURL(project: ProjectEntity, extension ext: String) -> URL {
        let invalid = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ ")).inverted
        let safe = (project.projectNumber + "_" + project.name).components(separatedBy: invalid).joined().replacingOccurrences(of: " ", with: "_")
        let bounded = String(safe.prefix(60))
        return FileManager.default.temporaryDirectory.appendingPathComponent(bounded.isEmpty ? "SteelFlow_Quote" : bounded).appendingPathExtension(ext)
    }
}
