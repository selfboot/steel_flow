import XCTest
import PDFKit
@testable import SteelFlow

@MainActor
final class PricingAndProjectTests: XCTestCase {
    func testGeneratedProjectNumbersDistinguishRapidCreations() {
        let first = Date(timeIntervalSince1970: 1_700_000_000)
        let second = first.addingTimeInterval(0.001)
        XCTAssertNotEqual(ProjectEntity.makeNumber(date: first), ProjectEntity.makeNumber(date: second))
        XCTAssertTrue(ProjectEntity.makeNumber(date: first).hasPrefix("Q-"))
    }

    func testPricingUsesDecimalAndExplicitOrder() {
        let pricing = PricingCalculator.total(
            subtotal: Decimal(string: "100.10")!,
            processingFee: Decimal(string: "10.20")!,
            otherFee: Decimal(string: "1.30")!,
            markupPercent: 10,
            taxPercent: 13
        )
        XCTAssertEqual(pricing.materialSubtotal, Decimal(string: "100.10"))
        XCTAssertEqual(pricing.fees, Decimal(string: "11.50"))
        XCTAssertEqual(pricing.markup, Decimal(string: "11.16"))
        XCTAssertEqual(pricing.preTax, Decimal(string: "122.76"))
        XCTAssertEqual(pricing.tax, Decimal(string: "15.96"))
        XCTAssertEqual(pricing.total, Decimal(string: "138.72"))
    }

    func testPriceBasisConversions() throws {
        let result = try CalculationEngine.calculate(.init(
            profile: .plate,
            geometry: .init(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter),
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 2,
            densityKgPerM3: 7_850,
            wastePercent: 0
        ))
        XCTAssertEqual(PricingCalculator.lineSubtotal(unitPrice: 2, basis: .perKilogram, result: result, lengthMeters: 6, quantity: 2), Decimal(string: "188.40"))
        XCTAssertEqual(PricingCalculator.lineSubtotal(unitPrice: 10, basis: .perMeter, result: result, lengthMeters: 6, quantity: 2), 120)
        XCTAssertEqual(PricingCalculator.lineSubtotal(unitPrice: 20, basis: .perPiece, result: result, lengthMeters: 6, quantity: 2), 40)
    }

    func testWasteAppliesToEveryPriceBasis() throws {
        let result = try CalculationEngine.calculate(.init(
            profile: .plate,
            geometry: .init(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter),
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 2,
            densityKgPerM3: 7_850,
            wastePercent: 10
        ))
        XCTAssertEqual(PricingCalculator.lineSubtotal(unitPrice: 10, basis: .perMeter, result: result, lengthMeters: 6, quantity: 2), 132)
        XCTAssertEqual(PricingCalculator.lineSubtotal(unitPrice: 20, basis: .perPiece, result: result, lengthMeters: 6, quantity: 2), 44)
    }

    func testCurrencyRoundingAndMarginPolicy() {
        let jpy = PricingCalculator.total(subtotal: 101, processingFee: 0, otherFee: 0, profitPercent: 10, profitMode: .markup, taxPercent: 10, currencyCode: "JPY")
        XCTAssertEqual(jpy.profit, 10)
        XCTAssertEqual(jpy.tax, 11)
        XCTAssertEqual(jpy.total, 122)

        let margin = PricingCalculator.total(subtotal: 80, processingFee: 0, otherFee: 0, profitPercent: 20, profitMode: .margin, taxPercent: 0, currencyCode: "USD")
        XCTAssertEqual(margin.preTax, 100)
        XCTAssertEqual(margin.profit, 20)
    }

    func testProjectRoundsEveryLineFeeBeforeSumming() {
        let project = ProjectEntity(name: "Rounding", currencyCode: "USD")
        project.items.append(makeItem(quantity: 1, unitPrice: 0, processing: Decimal(string: "0.005")!))
        project.items.append(makeItem(quantity: 1, unitPrice: 0, processing: Decimal(string: "0.005")!))
        let summary = ProjectCalculator.summarize(project)
        XCTAssertEqual(summary.pricing.fees, 0, "Banker's rounding is applied to each line fee before project summation")
    }

    func testProjectSummaryCombinesItemsFeesMarkupAndTax() {
        let project = ProjectEntity(name: "Test", currencyCode: "USD")
        project.markupPercentText = "10"
        project.taxPercentText = "5"
        project.items.append(makeItem(quantity: 2, unitPrice: 2, processing: 10))
        project.items.append(makeItem(quantity: 1, unitPrice: 3, processing: 5))
        let summary = ProjectCalculator.summarize(project)
        XCTAssertEqual(summary.lines.count, 2)
        XCTAssertEqual(summary.invalidItemCount, 0)
        XCTAssertGreaterThan(summary.netMassKg, 0)
        XCTAssertEqual(summary.pricing.fees, 15)
        XCTAssertGreaterThan(summary.pricing.total, summary.pricing.materialSubtotal)
        XCTAssertEqual(summary.lines.reduce(Decimal.zero) { $0 + $1.customerQuoteAmount }, summary.pricing.preTax)
        XCTAssertNotEqual(summary.lines.first?.customerQuoteAmount, summary.lines.first?.materialSubtotal)
    }

    func testInvalidItemDoesNotContributeHiddenFees() {
        let project = ProjectEntity(name: "Invalid fee", currencyCode: "USD")
        let invalid = makeItem(quantity: 1, unitPrice: 2, processing: 99)
        invalid.lengthValue = 0
        invalid.otherFeeText = "25"
        project.items.append(invalid)

        let summary = ProjectCalculator.summarize(project)
        XCTAssertEqual(summary.lines.count, 0)
        XCTAssertEqual(summary.invalidItemCount, 1)
        XCTAssertEqual(summary.pricing.fees, 0)
        XCTAssertEqual(summary.pricing.total, 0)
    }

    func testMalformedAndNegativePricingInvalidatesItem() {
        let project = ProjectEntity(name: "Bad price", currencyCode: "USD")
        let malformed = makeItem(quantity: 1, unitPrice: 2, processing: 0)
        malformed.unitPriceText = "not-a-price"
        let negative = makeItem(quantity: 1, unitPrice: 2, processing: 0)
        negative.processingFeeText = "-1"
        project.items.append(contentsOf: [malformed, negative])

        let summary = ProjectCalculator.summarize(project)
        XCTAssertEqual(summary.lines.count, 0)
        XCTAssertEqual(summary.invalidItemCount, 2)
        XCTAssertEqual(summary.pricing.total, 0)
    }

    func testQuickCalculatorRejectsInvalidPricingAndPreviewsValidTotal() throws {
        let draft = CalculatorDraft(profile: .plate)
        let calculation = try XCTUnwrap(draft.result(locale: Locale(identifier: "en_US")))
        let result = try calculation.get()
        draft.unitPriceText = "-1"
        XCTAssertNil(draft.pricing(locale: Locale(identifier: "en_US"), result: result, currencyCode: "USD"))
        XCTAssertNil(draft.makeItem(materialName: "Carbon steel", locale: Locale(identifier: "en_US"), sortIndex: 0))

        draft.unitPriceText = "2"
        draft.processingFeeText = "10"
        let pricing = try XCTUnwrap(draft.pricing(locale: Locale(identifier: "en_US"), result: result, currencyCode: "USD"))
        XCTAssertEqual(pricing.materialSubtotal, Decimal(string: "94.20"))
        XCTAssertEqual(pricing.total, Decimal(string: "104.20"))
    }

    func testSavedPriceHistoryPopulatesTraceableCalculatorFields() {
        let entry = PriceBookEntryEntity(
            name: "August supplier quote",
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            materialGrade: "Q355B",
            supplier: "Supplier A",
            region: "Shanghai",
            currencyCode: "CNY",
            priceBasis: .perKilogram,
            unitPrice: Decimal(string: "4.25")!,
            includesTax: true,
            effectiveAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let draft = CalculatorDraft(profile: .plate)
        draft.apply(priceEntry: entry)
        XCTAssertEqual(draft.unitPriceText, "4.25")
        XCTAssertEqual(draft.priceSource, .history)
        XCTAssertEqual(draft.priceSourceName, "Supplier A")
        XCTAssertEqual(draft.priceRegion, "Shanghai")
        XCTAssertEqual(draft.materialGrade, "Q355B")
        XCTAssertTrue(draft.priceIncludesTax)
    }

    func testPricingPolicyRejectsNegativeTaxAndImpossibleMargin() {
        let project = ProjectEntity(name: "Bad policy", currencyCode: "USD")
        project.taxPercentText = "-1"
        XCTAssertFalse(project.isPricingPolicyValid)
        project.taxPercentText = "10"
        project.profitMode = .margin
        project.markupPercentText = "100"
        XCTAssertFalse(project.isPricingPolicyValid)
    }

    func testDecimalParserRequiresWholeValidLocaleAwareInput() {
        XCTAssertNil(DecimalParser.parse("12abc", locale: Locale(identifier: "en_US")))
        XCTAssertNil(DecimalParser.parse("1,2", locale: Locale(identifier: "en_US")))
        XCTAssertEqual(DecimalParser.parse("1,234.50", locale: Locale(identifier: "en_US")), Decimal(string: "1234.50"))
        XCTAssertEqual(DecimalParser.parse("1.234,50", locale: Locale(identifier: "de_DE")), Decimal(string: "1234.50"))
    }

    func testLocalizedPricingInputIsCanonicalizedForStableStorage() {
        let item = makeItem(quantity: 1, unitPrice: 1, processing: 0)
        item.unitPriceText = "4,25"
        item.processingFeeText = "1,50"
        XCTAssertTrue(item.canonicalizePricing(locale: Locale(identifier: "de_DE")))
        XCTAssertEqual(item.unitPriceText, "4.25")
        XCTAssertEqual(item.processingFeeText, "1.5")
        XCTAssertTrue(item.isPricingValid)
    }

    func testCurrencyMigrationRequiresExplicitAction() {
        let converted = ProjectEntity(name: "Convert", currencyCode: "USD")
        let item = makeItem(quantity: 1, unitPrice: 10, processing: 2)
        item.otherFeeText = "1"
        converted.items.append(item)
        XCTAssertTrue(CurrencyMigration.apply(to: converted, newCurrency: "JPY", mode: .convert, rate: 150))
        XCTAssertEqual(converted.currencyCode, "JPY")
        XCTAssertEqual(item.unitPrice, 1_500)
        XCTAssertEqual(item.processingFee, 300)
        XCTAssertEqual(item.otherFee, 150)
        XCTAssertEqual(item.priceSource, .manual)

        let cleared = ProjectEntity(name: "Clear", currencyCode: "USD")
        let clearedItem = makeItem(quantity: 1, unitPrice: 10, processing: 2)
        cleared.items.append(clearedItem)
        XCTAssertTrue(CurrencyMigration.apply(to: cleared, newCurrency: "CNY", mode: .clearAmounts))
        XCTAssertEqual(clearedItem.unitPrice, 0)
        XCTAssertEqual(clearedItem.processingFee, 0)

        let kept = ProjectEntity(name: "Keep", currencyCode: "USD")
        let keptItem = makeItem(quantity: 1, unitPrice: 10, processing: 2)
        kept.items.append(keptItem)
        XCTAssertTrue(CurrencyMigration.apply(to: kept, newCurrency: "EUR", mode: .keepAmounts))
        XCTAssertEqual(keptItem.unitPrice, 10)
    }

    func testCurrencyMigrationRejectsInvalidCodeAndRate() {
        let project = ProjectEntity(name: "Invalid", currencyCode: "USD")
        project.items.append(makeItem(quantity: 1, unitPrice: 10, processing: 0))
        XCTAssertFalse(CurrencyMigration.apply(to: project, newCurrency: "NOPE", mode: .clearAmounts))
        XCTAssertFalse(CurrencyMigration.apply(to: project, newCurrency: "CNY", mode: .convert, rate: 0))
        XCTAssertEqual(project.currencyCode, "USD")

        let invalidPrices = ProjectEntity(name: "Invalid prices", currencyCode: "USD")
        let invalidItem = makeItem(quantity: 1, unitPrice: 10, processing: 0)
        invalidItem.unitPriceText = "bad"
        invalidPrices.items.append(invalidItem)
        XCTAssertFalse(CurrencyMigration.apply(to: invalidPrices, newCurrency: "CNY", mode: .convert, rate: 7))
        XCTAssertEqual(invalidPrices.currencyCode, "USD")
        XCTAssertEqual(invalidItem.unitPriceText, "bad")
    }

    func testCSVIsMachineReadableUTF8WithBOM() throws {
        let project = ProjectEntity(name: "报价 Test", projectNumber: "Q-1", currencyCode: "CNY")
        project.items.append(makeItem(quantity: 2, unitPrice: 2, processing: 0))
        let url = try QuoteExportService.csvURL(for: project)
        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.starts(with: [0xEF, 0xBB, 0xBF]))
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("profile_kind"))
        XCTAssertTrue(text.contains("roundTube"))
        XCTAssertTrue(text.contains("CNY"))
        XCTAssertTrue(text.contains("row_type"))
        XCTAssertTrue(text.contains("area_m2"))
        XCTAssertTrue(text.contains("waste_adjusted_mass_kg"))
        XCTAssertTrue(text.contains("project_summary"))
        XCTAssertTrue(text.contains("project_total"))
        let rows = text.replacingOccurrences(of: "\u{FEFF}", with: "").split(whereSeparator: { $0.isNewline })
        let headerColumnCount = rows[0].split(separator: ",", omittingEmptySubsequences: false).count
        XCTAssertEqual(headerColumnCount, 31)
        XCTAssertEqual(rows[1].split(separator: ",", omittingEmptySubsequences: false).count, headerColumnCount)
        XCTAssertEqual(rows[2].split(separator: ",", omittingEmptySubsequences: false).count, headerColumnCount)
    }

    func testCSVLocalizesBuiltInMaterialForQuoteLanguage() throws {
        let project = ProjectEntity(name: "English quote", quoteLanguage: "en", currencyCode: "USD")
        let item = makeItem(quantity: 1, unitPrice: 2, processing: 0)
        item.materialName = "碳钢"
        project.items.append(item)
        let text = try String(contentsOf: QuoteExportService.csvURL(for: project), encoding: .utf8)
        XCTAssertTrue(text.contains("\"Carbon steel\""))
        XCTAssertFalse(text.contains("\"碳钢\""))
    }

    func testCSVRejectsInvalidPricingInsteadOfSilentlyUsingZero() {
        let project = ProjectEntity(name: "Invalid", currencyCode: "USD")
        let item = makeItem(quantity: 1, unitPrice: 2, processing: 0)
        item.unitPriceText = "bad"
        project.items.append(makeItem(quantity: 1, unitPrice: 2, processing: 0))
        project.items.append(item)
        XCTAssertThrowsError(try QuoteExportService.csvURL(for: project)) {
            XCTAssertEqual($0 as? QuoteExportError, .invalidPricing)
        }
    }

    func testPDFProducesMultiplePageCapableDocument() throws {
        let project = ProjectEntity(name: "Global Quote", projectNumber: "Q-2", customerName: "Acme", quoteLanguage: "en", currencyCode: "USD")
        for index in 0..<40 {
            let item = makeItem(quantity: index + 1, unitPrice: 2, processing: 0)
            item.sortIndex = index
            project.items.append(item)
        }
        let url = try QuoteExportService.pdfURL(for: project, company: nil)
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 1_000)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
    }

    func testCustomerPDFHidesInternalCostAndProfitBreakdownAndProCanRemoveBranding() throws {
        let project = ProjectEntity(name: "Customer quote", projectNumber: "Q-SAFE", customerName: "Acme", quoteLanguage: "en", currencyCode: "USD")
        project.markupPercentText = "25"
        let item = makeItem(quantity: 2, unitPrice: 2, processing: 10)
        item.otherFeeText = "5"
        project.items.append(item)
        project.terms = "Net 30"

        let freeURL = try QuoteExportService.pdfURL(for: project, company: nil, includeBranding: true)
        let freeText = try XCTUnwrap(PDFDocument(url: freeURL)?.string)
        XCTAssertTrue(freeText.contains("Subtotal"))
        XCTAssertTrue(freeText.contains("Generated by SteelFlow"))
        XCTAssertFalse(freeText.contains("Material subtotal"))
        XCTAssertFalse(freeText.contains("Processing and other fees"))
        XCTAssertFalse(freeText.contains("Markup"))
        XCTAssertFalse(freeText.contains("Net 30"))

        let proURL = try QuoteExportService.pdfURL(for: project, company: nil, includeBranding: false)
        let proText = try XCTUnwrap(PDFDocument(url: proURL)?.string)
        XCTAssertFalse(proText.contains("Generated by SteelFlow"))
        XCTAssertTrue(proText.contains("Net 30"))
    }

    func testPaginatorAlwaysReservesFinalTotalsArea() throws {
        XCTAssertEqual(QuotePaginator.pageRowCounts(itemCount: 14, pageHeight: 841.8), [13, 1])
        XCTAssertEqual(QuotePaginator.pageRowCounts(itemCount: 13, pageHeight: 792), [11, 2])

        let a4 = ProjectEntity(name: "A4 boundary", currencyCode: "USD", paperSize: .a4)
        for index in 0..<14 { let item = makeItem(quantity: 1, unitPrice: 2, processing: 0); item.sortIndex = index; a4.items.append(item) }
        let url = try QuoteExportService.pdfURL(for: a4, company: nil)
        let provider = try XCTUnwrap(CGDataProvider(url: url as CFURL))
        let document = try XCTUnwrap(CGPDFDocument(provider))
        XCTAssertEqual(document.numberOfPages, 2)
    }

    func testQuoteSnapshotFreezesInputsResultsAndPrices() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let project = ProjectEntity(name: "Snapshot", currencyCode: "USD")
        let item = makeItem(quantity: 2, unitPrice: 2, processing: 3)
        item.priceSource = .manual
        item.priceSourceName = "Supplier A"
        item.descriptionText = "Customer line description"
        item.internalNote = "Internal note"
        project.items.append(item)
        let company = CompanyProfileEntity(companyName: "Acme Steel", contactName: "Ada", email: "ada@example.com")
        let expectedCustomerQuoteAmount = ProjectCalculator.summarize(project).lines.first?.customerQuoteAmount
        let data = try QuoteExportService.snapshotData(for: project, company: company, generatedAt: fixedDate, includeBranding: false)
        item.unitPriceText = "999"
        item.quantity = 99

        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(QuoteSnapshotPayload.self, from: data)
        XCTAssertEqual(snapshot.schemaVersion, 3)
        XCTAssertEqual(snapshot.generatedAt, fixedDate)
        XCTAssertEqual(snapshot.lines.first?.unitPrice, 2)
        XCTAssertEqual(snapshot.lines.first?.quantity, 2)
        XCTAssertEqual(snapshot.lines.first?.priceSourceName, "Supplier A")
        XCTAssertEqual(snapshot.lines.first?.customerQuoteAmount, expectedCustomerQuoteAmount)
        XCTAssertEqual(snapshot.lines.first?.descriptionText, "Customer line description")
        XCTAssertEqual(snapshot.lines.first?.internalNote, "Internal note")
        XCTAssertEqual(snapshot.company?.companyName, "Acme Steel")
        XCTAssertEqual(snapshot.paperSize, PaperSize.a4.rawValue)
        XCTAssertFalse(snapshot.includeBranding)
        XCTAssertNotEqual(snapshot.totals.total, 0)
    }

    private func makeItem(quantity: Int, unitPrice: Decimal, processing: Decimal) -> CalculationItemEntity {
        CalculationItemEntity(
            profile: .roundTube,
            geometry: .init(values: [.outerDiameter: 60.3, .wallThickness: 3.2], lengthUnit: .millimeter),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: quantity,
            wastePercent: 5,
            priceBasis: .perKilogram,
            unitPrice: unitPrice,
            processingFee: processing
        )
    }
}
