import XCTest
import SwiftData
import PDFKit
@testable import SteelFlow

@MainActor final class WorkflowTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")
    private func item() -> CalculationItemEntity {
        CalculationItemEntity(profile: .squareTube, geometry: .init(values: [.outerSide: 50, .wallThickness: 3], lengthUnit: .millimeter),
            materialID: "carbon-steel", materialName: "Carbon steel", densityKgPerM3: 7850, lengthValue: 2, lengthUnit: .meter,
            quantity: 4, wastePercent: 5, priceBasis: .perKilogram, unitPrice: 5, processingFee: 10, otherFee: 2,
            priceSource: .history, priceSourceName: "Supplier A", materialGrade: "Q235B", priceIncludesTax: true)
    }
    private func project() -> ProjectEntity {
        let value = ProjectEntity(name: "Workshop", customerName: "Customer", quoteLanguage: "en", currencyCode: "USD")
        value.items = [item()]; value.markupPercentText = "20"; value.taxPercentText = "8"
        return value
    }
    private func container() throws -> ModelContainer {
        let schema = Schema([ProjectEntity.self, CalculationItemEntity.self, MaterialEntity.self, PriceBookEntryEntity.self,
            CustomerEntity.self, CompanyProfileEntity.self, QuoteSnapshotEntity.self, AppPreferenceEntity.self])
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    }
    func testCrossCurrencySaveConvertsAllAmountsWithoutRoundingUnitPriceEarly() {
        let line = item()
        XCTAssertTrue(PriceBasisConversion.migrate(line, from: "USD", to: "CNY", mode: .convert, rate: Decimal(string: "7.12345")))
        XCTAssertEqual(line.unitPrice, Decimal(string: "35.61725"))
        XCTAssertEqual(line.processingFee, Decimal(string: "71.23"))
        XCTAssertEqual(line.otherFee, Decimal(string: "14.25"))
        XCTAssertEqual(line.priceSource, .manual)
        XCTAssertFalse(line.priceIncludesTax)
        XCTAssertTrue(line.priceSourceName.contains("USD → CNY"))
    }
    func testInvalidCurrencyConversionDoesNotPartiallyMutateAndClearRemovesAllMoney() {
        let line = item()
        XCTAssertFalse(PriceBasisConversion.migrate(line, from: "USD", to: "CNY", mode: .convert, rate: nil))
        XCTAssertEqual(line.unitPrice, 5); XCTAssertEqual(line.processingFee, 10)
        XCTAssertTrue(PriceBasisConversion.migrate(line, from: "USD", to: "CNY", mode: .clearAmounts, rate: nil))
        XCTAssertEqual(line.unitPrice + line.processingFee + line.otherFee, 0)
        XCTAssertEqual(line.priceSourceName, "")
    }
    func testEquivalentPricingUnitsPreserveCustomerTotal() throws {
        let line = item(), p = project()
        p.items = [line]
        let original = ProjectCalculator.summarize(p).pricing.total
        line.unitPriceText = try XCTUnwrap(PriceBasisConversion.convert(line.unitPrice, from: .perKilogram, to: .perPound)).description
        line.priceBasisRaw = PriceBasis.perPound.rawValue
        XCTAssertEqual(ProjectCalculator.summarize(p).pricing.total, original)
        XCTAssertNil(PriceBasisConversion.convert(5, from: .perKilogram, to: .perPiece))
    }
    func testHistoricalPriceRequiresReviewAfterMaterialChanges() {
        let draft = CalculatorDraft(profile: .plate)
        draft.apply(priceEntry: PriceBookEntryEntity(name: "Steel price", currencyCode: "USD", priceBasis: .perKilogram, unitPrice: 5))
        draft.apply(material: MaterialEntity(id: "aluminum", name: "Aluminum", densityKgPerM3: 2700))
        XCTAssertTrue(draft.priceNeedsReview)
        draft.clearPrice()
        XCTAssertFalse(draft.priceNeedsReview); XCTAssertEqual(draft.unitPriceText, "0")
    }
    func testIncompleteDraftAndFavoritesSurviveRelaunchWithoutAProject() throws {
        let suite = "WorkflowTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = CalculationLibrary(defaults: defaults)
        let draft = CalculatorDraft(profile: .squareTube)
        draft.lengthText = ""; draft.itemDescription = "unfinished"
        let state = DraftState(draft, currency: "CNY", locale: locale)
        library.saveDraft(state, key: "quick.squareTube")
        draft.lengthText = "2.5"
        library.record(DraftState(draft, currency: "CNY", locale: locale), favorite: true)
        let relaunched = CalculationLibrary(defaults: defaults)
        XCTAssertEqual(relaunched.payload.drafts["quick.squareTube"]?.length, "")
        XCTAssertEqual(relaunched.records.count, 1); XCTAssertTrue(relaunched.records[0].isFavorite)
        XCTAssertEqual(relaunched.records[0].state.currency, "CNY")
        let french = relaunched.records[0].state.makeDraft(locale: Locale(identifier: "fr_FR"))
        XCTAssertEqual(french.lengthText, "2,5")
        XCTAssertNotNil(french.result(locale: Locale(identifier: "fr_FR")))
    }
    func testPerPieceHistoricalPriceNeedsReviewWhenStockLengthChanges() {
        let draft = CalculatorDraft(profile: .squareTube)
        draft.lengthText = "2"
        draft.apply(priceEntry: PriceBookEntryEntity(name: "Two-meter stock", currencyCode: "USD", priceBasis: .perPiece, unitPrice: 50))
        draft.editStockLength("3")
        XCTAssertTrue(draft.priceNeedsReview)
        XCTAssertEqual(draft.unitPriceText, "50")
        draft.clearPrice()
        XCTAssertFalse(draft.priceNeedsReview)
    }
    func testDuplicatingItemDoesNotAliasSource() {
        let source = item()
        let copy = source.copyItem()
        XCTAssertNotEqual(source.id, copy.id)
        copy.quantity = 20
        XCTAssertEqual(source.quantity, 4)
        XCTAssertEqual(copy.materialGrade, "Q235B")
    }
    func testTemplateReuseClearsOldPricesButKeepsQuotePolicy() {
        let source = project(); source.terms = "Net 30"; source.customerContact = "555"; source.showQuoteUnitPrice = true
        let copy = ProjectCloner.copy(source, name: "New job", clearPrices: true)
        XCTAssertNotEqual(source.id, copy.id)
        XCTAssertEqual(copy.items.first?.unitPrice, 0)
        XCTAssertEqual(source.items.first?.unitPrice, 5)
        XCTAssertEqual(copy.terms, "Net 30"); XCTAssertEqual(copy.markupPercent, 20)
        XCTAssertTrue(copy.showQuoteUnitPrice)
    }
    func testBulkUndoRestoresPricesAndProvenance() {
        let line = item()
        let state = ItemPricingState(line)
        line.unitPriceText = "99"; line.priceSourceName = ""; line.wastePercent = 30
        state.restore(line)
        XCTAssertEqual(line.unitPrice, 5); XCTAssertEqual(line.wastePercent, 5)
        XCTAssertEqual(line.priceSourceName, "Supplier A"); XCTAssertTrue(line.priceIncludesTax)
    }
    func testFrozenQuoteRegenerationKeepsOldAmountDateAndUnits() throws {
        let p = project(); p.unitSystem = .imperial
        let data = try QuoteExportService.snapshotData(for: p, generatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let frozen = try QuoteExportService.decodeSnapshot(data)
        p.items[0].unitPriceText = "99"; p.unitSystem = .metric
        let restored = QuoteSnapshotRestorer.project(frozen)
        XCTAssertEqual(restored.items.first?.unitPrice, 5); XCTAssertEqual(restored.unitSystem, .imperial)
        XCTAssertEqual(frozen.generatedAt, Date(timeIntervalSince1970: 1_700_000_000))
        let url = try QuoteExportService.pdfURL(snapshot: frozen)
        let text = try XCTUnwrap(PDFDocument(url: url)?.string)
        XCTAssertTrue(text.contains("lb")); XCTAssertTrue(text.contains("ft")); XCTAssertTrue(text.contains("Q235B"))
        XCTAssertFalse(text.contains("Supplier A"))
        let pdfAttachment = XCTAttachment(contentsOfFile: url); pdfAttachment.name = "imperial-frozen-quote.pdf"; pdfAttachment.lifetime = .keepAlways; add(pdfAttachment)
        if let page = PDFDocument(url: url)?.page(at: 0) {
            let attachment = XCTAttachment(image: page.thumbnail(of: CGSize(width: 1190, height: 1684), for: .mediaBox))
            attachment.name = "imperial-quote-page"; attachment.lifetime = .keepAlways; add(attachment)
        }
        XCTAssertEqual(ProjectCalculator.summarize(restored).pricing.total, frozen.totals.total)
    }
    func testPDFDoesNotLoseLongTermsDescriptionsOrStockLength() throws {
        for language in ["en", "zh-Hans"] {
            let p = project(); p.quoteLanguage = language; p.paperSize = .letter
            p.terms = String(repeating: "Payment terms 付款条款需完整保留。", count: 120) + "\nEND-TERMS"
            p.items[0].descriptionText = String(repeating: "Custom part 复杂规格描述。", count: 60) + "\nEND-DESCRIPTION"
            let url = try QuoteExportService.pdfURL(for: p, company: nil, includeBranding: false)
            let pdf = try XCTUnwrap(PDFDocument(url: url)), text = try XCTUnwrap(pdf.string)
            XCTAssertGreaterThan(pdf.pageCount, 1)
            for index in [0, pdf.pageCount - 1] {
                if let page = pdf.page(at: index) {
                    let attachment = XCTAttachment(image: page.thumbnail(of: CGSize(width: 1224, height: 1584), for: .mediaBox))
                    attachment.name = "long-quote-" + language + "-" + String(index); attachment.lifetime = .keepAlways; add(attachment)
                }
            }
            XCTAssertTrue(text.contains("END-TERMS")); XCTAssertTrue(text.contains("END-DESCRIPTION"))
            XCTAssertTrue(text.contains("2 m")); XCTAssertTrue(text.contains("Q235B"))
        }
    }
    func testCSVExportsSeparateCustomerPricesFromInternalCostsAndEscapeFormulas() throws {
        let p = project(); p.items[0].descriptionText = "=HYPERLINK(\"bad\")"; p.items[0].internalNote = "secret margin"
        let frozen = try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: p))
        let customer = String(decoding: QuoteCSVRenderer.data(frozen, kind: .customer), as: UTF8.self)
        XCTAssertFalse(customer.contains("Supplier A")); XCTAssertFalse(customer.contains("secret margin"))
        XCTAssertEqual(customer.components(separatedBy: "\"project_summary\"").count, 2)
        XCTAssertTrue(customer.contains("sales_price_per_piece")); XCTAssertTrue(customer.contains("'=HYPERLINK"))
        let costs = String(decoding: QuoteCSVRenderer.data(frozen, kind: .internalCosts), as: UTF8.self)
        XCTAssertTrue(costs.contains("Supplier A")); XCTAssertTrue(costs.contains("secret margin"))
        let cut = String(decoding: QuoteCSVRenderer.data(frozen, kind: .cutting), as: UTF8.self)
        XCTAssertFalse(cut.contains("purchase_price")); XCTAssertFalse(cut.contains("sales_amount"))
    }
    func testEnhancedBackupRestoresTemplatesBrandingAndCalculationLibrary() throws {
        let p = project(); p.isTemplate = true; p.isPinned = true; p.customerContact = "Contact"; p.showQuoteMass = false; p.showQuoteUnitPrice = true
        let company = CompanyProfileEntity(companyName: "Workshop"); company.logoData = Data([1, 2, 3]); company.defaultTerms = "Net 30"
        let state = DraftState(item: p.items[0], currency: "USD", locale: locale)
        let library = CalculationLibraryPayload(records: [.init(state: state, isFavorite: true)], drafts: ["quick.squareTube": state])
        let document = try BackupService.makeDocument(projects: [p], materials: [], company: company, libraryData: JSONEncoder().encode(library))
        XCTAssertEqual(try BackupService.preview(data: document.data).schemaVersion, 4)
        let c = try container()
        let imported = try BackupService.importCopy(data: document.data, into: c.mainContext)
        let restored = try XCTUnwrap(c.mainContext.fetch(FetchDescriptor<ProjectEntity>()).first)
        XCTAssertTrue(restored.isTemplate); XCTAssertTrue(restored.isPinned); XCTAssertFalse(restored.showQuoteMass); XCTAssertTrue(restored.showQuoteUnitPrice)
        XCTAssertEqual(restored.customerContact, "Contact")
        let brand = try XCTUnwrap(c.mainContext.fetch(FetchDescriptor<CompanyProfileEntity>()).first)
        XCTAssertEqual(brand.logoData, company.logoData); XCTAssertEqual(brand.defaultTerms, "Net 30")
        let restoredLibrary = try JSONDecoder().decode(CalculationLibraryPayload.self, from: XCTUnwrap(imported.libraryData))
        XCTAssertTrue(restoredLibrary.records[0].isFavorite)
    }
    func testTinyGeometryUnitRoundTripDoesNotBecomeZero() throws {
        let draft = CalculatorDraft(profile: .roundBar)
        draft.dimensionTexts[.diameter] = "0.00001"
        for _ in 0..<10 { draft.convertGeometry(to: .inch, locale: locale); draft.convertGeometry(to: .millimeter, locale: locale) }
        XCTAssertEqual(try XCTUnwrap(DecimalParser.double(draft.dimensionTexts[.diameter]!, locale: locale)), 0.00001, accuracy: 1e-9)
    }
    func testScopedPricesMatchEquivalentUnitsButRejectOtherWallThickness() throws {
        let metric = GeometryInput(values: [.outerSide: 50, .wallThickness: 3], lengthUnit: .millimeter)
        let equivalent = GeometryInput(values: [.outerSide: 50 / 25.4, .wallThickness: 3 / 25.4], lengthUnit: .inch)
        let different = GeometryInput(values: [.outerSide: 50, .wallThickness: 4], lengthUnit: .millimeter)
        let data = try JSONEncoder().encode(metric)
        XCTAssertTrue(PriceApplicability.matches(profile: .squareTube, geometry: equivalent, entryProfile: "squareTube", entryGeometry: data))
        XCTAssertFalse(PriceApplicability.matches(profile: .squareTube, geometry: different, entryProfile: "squareTube", entryGeometry: data))
        XCTAssertFalse(PriceApplicability.matches(profile: .roundTube, geometry: metric, entryProfile: "squareTube", entryGeometry: data))
        XCTAssertTrue(PriceApplicability.matches(profile: .squareTube, geometry: different, entryProfile: nil, entryGeometry: nil))
        XCTAssertFalse(PriceApplicability.matches(profile: .squareTube, geometry: metric, entryProfile: "squareTube", entryGeometry: data, lengthMeters: 6, entryLengthMeters: 2))
        XCTAssertTrue(PriceApplicability.matches(profile: .squareTube, geometry: metric, entryProfile: "squareTube", entryGeometry: data, lengthMeters: 2, entryLengthMeters: 2))
        let price = PriceBookEntryEntity(name: "50 × 3 tube", currencyCode: "USD", priceBasis: .perKilogram, unitPrice: 5)
        price.applicableProfile = "squareTube"; price.applicableGeometry = data
        let document = try BackupService.makeDocument(projects: [], materials: [], company: nil, priceBook: [price])
        let c = try container()
        _ = try BackupService.importCopy(data: document.data, into: c.mainContext)
        let restored = try XCTUnwrap(c.mainContext.fetch(FetchDescriptor<PriceBookEntryEntity>()).first)
        XCTAssertEqual(restored.applicableGeometry, data); XCTAssertEqual(restored.applicableProfile, "squareTube")
    }

}
