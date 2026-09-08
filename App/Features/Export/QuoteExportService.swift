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
        var logoData: Data? = nil
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

    var unitSystemRaw: String? = nil
    var showMass: Bool? = nil
    var showUnitPrice: Bool? = nil
    var customerContact: String? = nil
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
    var company: Company?
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
        var payload = QuoteSnapshotPayload(
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
        payload.unitSystemRaw = project.unitSystemRaw
        payload.showMass = project.showQuoteMass
        payload.showUnitPrice = project.showQuoteUnitPrice
        payload.customerContact = project.customerContact
        payload.company?.logoData = company?.logoData
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

    static func decodeSnapshot(_ data: Data) throws -> QuoteSnapshotPayload {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(QuoteSnapshotPayload.self, from: data)
    }

    static func pdfURL(for project: ProjectEntity, company: CompanyProfileEntity?, generatedAt: Date = .now, includeBranding: Bool = true) throws -> URL {
        let payload = try decodeSnapshot(snapshotData(for: project, company: company, generatedAt: generatedAt, includeBranding: includeBranding))
        return try pdfURL(snapshot: payload)
    }

    static func pdfURL(snapshot: QuoteSnapshotPayload) throws -> URL {
        try QuotePDFRenderer.render(snapshot)
    }

    private static func machine(_ value: Double) -> String { String(format: "%.10g", locale: Locale(identifier: "en_US_POSIX"), value) }
    private static func iso8601(_ value: Date) -> String { ISO8601DateFormatter().string(from: value) }
    private static func csvCell(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
    private static func temporaryURL(project: ProjectEntity, extension ext: String) -> URL {
        let invalid = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ ")).inverted
        let safe = (project.projectNumber + "_" + project.name).components(separatedBy: invalid).joined().replacingOccurrences(of: " ", with: "_")
        let bounded = String(safe.prefix(60))
        return FileManager.default.temporaryDirectory.appendingPathComponent((bounded.isEmpty ? "SteelFlow_Quote" : bounded) + "_" + UUID().uuidString.prefix(8)).appendingPathExtension(ext)
    }
}
