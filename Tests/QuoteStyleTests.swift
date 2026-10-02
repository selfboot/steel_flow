import XCTest
import PDFKit
import SwiftData
@testable import SteelFlow

@MainActor final class QuoteStyleTests: XCTestCase {
    func testStylesSurviveSnapshotCopyTemplateAndBackup() throws {
        for style in QuoteStyle.allCases {
            let sample = try QuoteStyleSample.snapshot(language: "en")
            let project = QuoteSnapshotRestorer.project(sample)
            project.quoteStyle = style
            let encoded = try QuoteExportService.snapshotData(for: project, locale: Locale(identifier: project.quoteLanguage))
            let frozen = try QuoteExportService.decodeSnapshot(encoded)
            project.quoteStyle = .classic
            XCTAssertEqual(frozen.quoteStyle, style)
            let restored = QuoteSnapshotRestorer.project(frozen)
            XCTAssertEqual(restored.quoteStyle, style)
            XCTAssertEqual(ProjectCloner.copy(restored, name: "Template", clearPrices: true).quoteStyle, style)
            let schema = Schema([ProjectEntity.self, CalculationItemEntity.self, MaterialEntity.self, PriceBookEntryEntity.self, CustomerEntity.self, CompanyProfileEntity.self, QuoteSnapshotEntity.self, AppPreferenceEntity.self])
            let container = try ModelContainer(for: schema, configurations: [.init(schema: schema, isStoredInMemoryOnly: true)])
            let backup = try BackupService.makeDocument(projects: [restored], materials: [], company: nil)
            _ = try BackupService.importCopy(data: backup.data, into: container.mainContext)
            XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<ProjectEntity>()).first?.quoteStyle, style)
        }
    }

    func testPreviewStyleOverridesProjectWithoutChangingSavedQuote() throws {
        let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "en"))
        project.quoteStyle = .blue
        project.paperSize = .letter
        let original = try QuoteExportService.snapshotData(for: project, locale: Locale(identifier: project.quoteLanguage))
        for style in QuoteStyle.allCases {
            let data = try QuoteExportService.snapshotData(for: project, includeBranding: false, quoteStyle: style, locale: Locale(identifier: project.quoteLanguage))
            let preview = try QuoteExportService.decodeSnapshot(data)
            XCTAssertEqual(preview.quoteStyle, style)
            XCTAssertEqual(preview.paperSize, project.paperSize.rawValue)
            XCTAssertFalse(preview.includeBranding)
            XCTAssertEqual(project.quoteStyle, .blue)
            XCTAssertEqual(try QuoteExportService.decodeSnapshot(original).quoteStyle, .blue)
        }
    }

    func testLegacyAndUnknownSnapshotStylesUseClassic() throws {
        let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "en"))
        project.quoteStyle = .forest
        let data = try QuoteExportService.snapshotData(for: project, locale: Locale(identifier: project.quoteLanguage))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "quoteStyleRaw")
        XCTAssertEqual(try QuoteExportService.decodeSnapshot(JSONSerialization.data(withJSONObject: json)).quoteStyle, .classic)
        json["quoteStyleRaw"] = "future-style"
        XCTAssertEqual(try QuoteExportService.decodeSnapshot(JSONSerialization.data(withJSONObject: json)).quoteStyle, .classic)
    }

    func testEveryStyleInEveryLanguageAndPaperKeepsContentAndBrandingRules() throws {
        for style in QuoteStyle.allCases where style != .classic {
            for language in AppLanguage.allCases {
                for paper in PaperSize.allCases {
                    let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: language.rawValue))
                    project.quoteStyle = style; project.paperSize = paper
                    project.showQuoteUnitPrice = true
                    project.items[0].descriptionText = "PART-001"
                    project.terms = "TERMS-END-0042"
                    let url = try QuoteExportService.pdfURL(for: project, company: nil, includeBranding: false, locale: Locale(identifier: project.quoteLanguage))
                    defer { try? FileManager.default.removeItem(at: url) }
                    let pdf = try XCTUnwrap(PDFDocument(url: url))
                    let text = try XCTUnwrap(pdf.string)
                    XCTAssertFalse(text.contains("SteelFlow"))
                    XCTAssertTrue(text.contains("PART-001"))
                    XCTAssertFalse(text.contains("TERMS-END-0042"))
                    XCTAssertFalse(text.contains("Material subtotal"))
                    let locale = Locale(identifier: language.rawValue)
                    let total = AppFormatters.decimal(ProjectCalculator.summarize(project).pricing.total, currencyCode: project.currencyCode, locale: locale)
                    func compact(_ s: String) -> String { s.filter { !$0.isWhitespace } }
                    XCTAssertTrue(compact(text).contains(compact(total)), "\(style)/\(language)/\(paper)")
                    for i in 0..<pdf.pageCount {
                        let page = try XCTUnwrap(pdf.page(at: i))
                        let bounds = page.bounds(for: .mediaBox)
                        for index in 0..<page.numberOfCharacters {
                            let rect = page.characterBounds(at: index)
                            if rect.isEmpty { continue }
                            XCTAssertTrue(bounds.insetBy(dx: -1, dy: -1).contains(rect), "Clipped glyph: \(style)/\(language)/\(paper)")
                        }
                    }
                    if paper == .a4 && [.english, .simplifiedChinese, .german, .japanese].contains(language) {
                        let image = XCTAttachment(image: try XCTUnwrap(pdf.page(at: 0)).thumbnail(of: CGSize(width: 1190, height: 1684), for: .mediaBox))
                        image.name = "style-\(style.rawValue)-\(language.rawValue)"; image.lifetime = .keepAlways; add(image)
                    }
                }
            }
            let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "en"))
            project.quoteStyle = style
            let url = try QuoteExportService.pdfURL(for: project, company: nil, includeBranding: true, locale: Locale(identifier: project.quoteLanguage))
            defer { try? FileManager.default.removeItem(at: url) }
            XCTAssertTrue(try XCTUnwrap(PDFDocument(url: url)?.string).contains("SteelFlow"))
        }
    }

    func testStyledLongQuotesPaginateWithoutLosingDescriptions() throws {
        for style in QuoteStyle.allCases where style != .classic {
            for paper in PaperSize.allCases {
                let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "de"))
                project.quoteStyle = style; project.paperSize = paper; project.showQuoteUnitPrice = true
                let first = try XCTUnwrap(project.items.first)
                project.items = (0..<24).map { i in
                    let copy = first.copyItem(); copy.descriptionText = "PART-\(i)-END"; copy.sortIndex = i; return copy
                }
                project.items[3].descriptionText = "LONGSTART " + String(repeating: "W", count: 500) + " LONGEND"
                project.terms = String(repeating: "Lieferbedingungen und Zahlungsbedingungen. 日本語の条件。\n", count: 32) + "FINAL-TERMS-END"
                let url = try QuoteExportService.pdfURL(for: project, company: nil, includeBranding: false, locale: Locale(identifier: project.quoteLanguage))
                defer { try? FileManager.default.removeItem(at: url) }
                let pdf = try XCTUnwrap(PDFDocument(url: url))
                let text = try XCTUnwrap(pdf.string)
                XCTAssertGreaterThan(pdf.pageCount, 2)
                for i in 0..<24 where i != 3 { XCTAssertTrue(text.contains("PART-\(i)-END")) }
                // Reading order includes numeric cells and continuation headers between lines.
                // Count the payload glyphs rather than requiring one contiguous extraction.
                XCTAssertEqual(text.filter { $0 == "W" }.count, 500, "\(style)/\(paper)")
                XCTAssertTrue(text.contains("LONGSTART")); XCTAssertTrue(text.contains("LONGEND"))
                XCTAssertFalse(text.contains("FINAL-TERMS-END"))
                for i in [0, 1, pdf.pageCount - 1] {
                    let image = XCTAttachment(image: try XCTUnwrap(pdf.page(at: i)).thumbnail(of: CGSize(width: 1190, height: 1684), for: .mediaBox))
                    image.name = "long-\(style.rawValue)-\(paper.rawValue)-\(i)"; image.lifetime = .keepAlways; add(image)
                }
            }
        }
    }

    func testPolishedHeadersAndLargeTotalsStayReadable() throws {
        for style in QuoteStyle.allCases where style != .classic {
            for paper in PaperSize.allCases {
                let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "de"))
                project.quoteStyle = style; project.paperSize = paper
                project.projectNumber = "QUOTE-" + String(repeating: "8", count: 120) + "-END"
                project.customerName = String(repeating: "Kundenunternehmen ", count: 12) + "CUSTOMER-END"
                project.items[0].unitPriceText = "987654321.12"
                let company = CompanyProfileEntity(companyName: String(repeating: "NORTHLINE METALS ", count: 8) + "COMPANY-END")
                company.email = "quotes@example.com"; company.address = "ADDRESS-END"
                let snapshot = try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: project, company: company, includeBranding: false, locale: Locale(identifier: project.quoteLanguage)))
                let url = try QuotePDFRenderer.render(snapshot)
                defer { try? FileManager.default.removeItem(at: url) }
                let pdf = try XCTUnwrap(PDFDocument(url: url))
                let text = try XCTUnwrap(pdf.string)
                for marker in ["CUSTOMER-END", "COMPANY-END", "ADDRESS-END", "-END"] { XCTAssertTrue(text.contains(marker)) }
                let total = AppFormatters.decimal(snapshot.totals.total, currencyCode: snapshot.currencyCode, locale: Locale(identifier: "de"))
                XCTAssertTrue(text.filter { !$0.isWhitespace }.contains(total.filter { !$0.isWhitespace }))
                let largeLineAmount = AppFormatters.decimal(snapshot.lines[0].customerQuoteAmount, currencyCode: snapshot.currencyCode, locale: Locale(identifier: "de"))
                XCTAssertTrue(text.components(separatedBy: "\n").contains { $0.filter { !$0.isWhitespace }.contains(largeLineAmount.filter { !$0.isWhitespace }) }, "Large line amounts should not break across rows")
                // The three-row summary should remain together when it fits on a page.
                let subtotalLabel = AppLocalization.text("quote.subtotal", locale: Locale(identifier: "de"))
                let totalLabel = AppLocalization.text("project.total", locale: Locale(identifier: "de"))
                XCTAssertTrue((0..<pdf.pageCount).contains { index in
                    let pageText = pdf.page(at: index)?.string ?? ""
                    return pageText.contains(subtotalLabel) && pageText.contains(totalLabel) && pageText.filter { !$0.isWhitespace }.contains(total.filter { !$0.isWhitespace })
                })
                for index in 0..<pdf.pageCount {
                    let page = try XCTUnwrap(pdf.page(at: index))
                    if index > 0 { XCTAssertTrue((page.string ?? "").contains("-END"), "Continuation header must retain the number suffix") }
                    let bounds = page.bounds(for: .mediaBox).insetBy(dx: 30, dy: 20)
                    for character in 0..<page.numberOfCharacters {
                        let rect = page.characterBounds(at: character)
                        if !rect.isEmpty { XCTAssertTrue(bounds.contains(rect), "\(style)/\(paper): \(rect)") }
                    }
                }
                let attachment = XCTAttachment(contentsOfFile: url)
                attachment.name = "polished-stress-\(style.rawValue)-\(paper.rawValue).pdf"; attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }

    func testQuotesOmitTermsAndFooterCopyInEveryStyleAndLanguage() throws {
        for style in QuoteStyle.allCases {
            for language in AppLanguage.allCases {
                for branding in [true, false] {
                    let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: language.rawValue))
                    project.quoteStyle = style
                    project.terms = "TERMS-PRIVATE " + String(repeating: "Do not print this paragraph. ", count: 200)
                    let snapshot = try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: project, includeBranding: branding, locale: Locale(identifier: project.quoteLanguage)))
                    XCTAssertEqual(snapshot.terms, project.terms, "Keep stored project and history data")
                    let url = try QuotePDFRenderer.render(snapshot)
                    defer { try? FileManager.default.removeItem(at: url) }
                    let pdf = try XCTUnwrap(PDFDocument(url: url))
                    let text = try XCTUnwrap(pdf.string)
                    let locale = Locale(identifier: language.rawValue)
                    XCTAssertFalse(text.contains("TERMS-PRIVATE"))
                    XCTAssertFalse(text.contains("Do not print"))
                    for key in ["quote.disclaimer", "quote.generated_by"] {
                        XCTAssertFalse(text.filter { !$0.isWhitespace }.contains(AppLocalization.text(key, locale: locale).filter { !$0.isWhitespace }))
                    }
                    XCTAssertEqual(pdf.pageCount, 1, "Hidden terms must not create pages")
                    XCTAssertEqual(text.contains("SteelFlow"), branding, "Existing header branding rule is preserved")
                    let page = try XCTUnwrap(pdf.page(at: 0))
                    let footer = page.selection(for: CGRect(x: 0, y: 0, width: page.bounds(for: .mediaBox).width, height: 45))?.string ?? ""
                    XCTAssertEqual(footer.trimmingCharacters(in: .whitespacesAndNewlines), "1", "Footer contains only the page number")
                }
            }
        }
    }

    func testCreateStyleSamples() throws {
        for style in QuoteStyle.allCases where style != .classic {
            var sample = try QuoteStyleSample.snapshot(language: "zh-Hans")
            sample.quoteStyleRaw = style.rawValue
            let url = try QuotePDFRenderer.render(sample)
            defer { try? FileManager.default.removeItem(at: url) }
            let attachment = XCTAttachment(contentsOfFile: url)
            attachment.name = "quote-style-\(style.rawValue).pdf"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
