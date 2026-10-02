import XCTest
import PDFKit
@testable import SteelFlow

final class LocalizationTests: XCTestCase {
    private func strings(for language: String) throws -> [String: String] {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
        let url = URL(fileURLWithPath: path).appendingPathComponent("Localizable.strings")
        return try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: String])
    }

    func testAllLanguagesHaveMatchingKeysAndFormatArguments() throws {
        let english = try strings(for: "en")
        let pattern = try NSRegularExpression(pattern: #"%(?:[0-9]+\$)?(?:lld|ld|d|@|f|s)"#)
        func arguments(_ value: String) -> [String] {
            pattern.matches(in: value, range: NSRange(value.startIndex..., in: value)).map {
                String(value[Range($0.range, in: value)!])
            }
        }
        for language in AppLanguage.allCases {
            let localized = try strings(for: language.rawValue)
            XCTAssertEqual(Set(english.keys), Set(localized.keys), language.rawValue)
            for (key, value) in localized {
                XCTAssertFalse(value.isEmpty, key)
                XCTAssertEqual(arguments(value), arguments(english[key] ?? ""), "\(language.rawValue): \(key)")
            }
        }
    }

    func testRegionalLanguageResolutionAndQuoteDefaults() {
        let cases: [(String, AppLanguage)] = [
            ("en_US", .english), ("zh_CN", .simplifiedChinese), ("zh_SG", .simplifiedChinese),
            ("zh_TW", .traditionalChinese), ("zh_HK", .traditionalChinese), ("zh_MO", .traditionalChinese),
            ("zh-Hant-US", .traditionalChinese), ("zh-Hans-TW", .simplifiedChinese),
            ("ja_JP", .japanese), ("ko_KR", .korean),
            ("de_DE", .german), ("de_AT", .german), ("de_CH", .german),
            ("es_ES", .spanish), ("es_MX", .spanish), ("es_US", .spanish),
            ("fr_FR", .french), ("fr_CA", .french), ("fr_CH", .french), ("it_IT", .english)
        ]
        for (identifier, expected) in cases {
            let locale = Locale(identifier: identifier)
            XCTAssertEqual(AppLanguage.resolve(locale), expected, identifier)
            XCTAssertEqual(AppLanguage.selected("system", systemLocale: locale), expected, identifier)
            XCTAssertEqual(AppLanguage.selected("ko", systemLocale: locale), .korean, "Explicit preference overrides system")
        }
        XCTAssertEqual(AppLocalization.text("tab.settings", locale: Locale(identifier: "zh_TW")), "設定")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "zh_HK")), "報價單")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "ja_JP")), "見積書")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "ko_KR")), "견적서")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "de_DE")), "ANGEBOT")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "es_MX")), "PRESUPUESTO")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "fr_CA")), "DEVIS")
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "it_IT")), "QUOTE")
    }

    func testSystemLanguageUsesFirstSupportedPreference() {
        XCTAssertEqual(AppLanguage.preferred(in: ["it-IT", "ja-JP", "en-US"]), .japanese)
        XCTAssertEqual(AppLanguage.preferred(in: ["fr-CA", "en-US"]), .french)
        XCTAssertEqual(AppLanguage.preferred(in: ["es-MX", "en-US"]), .spanish)
        XCTAssertEqual(AppLanguage.preferred(in: ["zh-TW", "en-US"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.preferred(in: ["zh-HK", "en-US"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.preferred(in: ["ko-KR", "en-US"]), .korean)
        XCTAssertEqual(AppLanguage.preferred(in: ["de-CH"]), .german)
        XCTAssertEqual(AppLanguage.preferred(in: ["it-IT"]), .english)
    }

    func testDynamicMessagesRespectEachAppLanguagePreference() {
        let original = UserDefaults.standard.object(forKey: "app.language")
        defer { UserDefaults.standard.set(original, forKey: "app.language") }
        for language in AppLanguage.allCases {
            UserDefaults.standard.set(language.rawValue, forKey: "app.language")
            XCTAssertEqual(AppLanguage.resolve(AppLocalization.preferredLocale), language)
            XCTAssertEqual(AppLocalization.text("quote.title"), AppLocalization.text("quote.title", locale: Locale(identifier: language.rawValue)))
        }
    }

    func testDynamicLocalizationAndEnglishCountsHonorExplicitLocale() {
        XCTAssertEqual(AppLocalization.text("purchase.free", locale: Locale(identifier: "zh-Hans")), "免费版")
        XCTAssertEqual(AppLocalization.text("purchase.free", locale: Locale(identifier: "en")), "Free plan")
        XCTAssertEqual(AppLocalization.count("project.item_count", value: 1, locale: Locale(identifier: "en")), "1 item")
        XCTAssertEqual(AppLocalization.count("project.item_count", value: 2, locale: Locale(identifier: "en")), "2 items")
    }

    func testCriticalKeysExistInEverySupportedLanguage() throws {
        let dynamicKeys =
            ProfileKind.allCases.flatMap { ["profile.\($0.rawValue)", "profile.\($0.rawValue).summary"] } +
            DimensionField.allCases.map { "dimension.\($0.rawValue)" } +
            MaterialCatalog.presets.flatMap { [$0.nameKey, $0.noteKey] }
        let fixedKeys = [
            "tab.calculate", "tab.projects", "tab.materials", "tab.settings",
            "calculator.hero.title", "calculator.result.total_mass", "calculator.save_to_project",
            "calculator.section.preview", "preview.invalid", "preview.scale_note",
            "preview.equivalent_square_note", "preview.accessibility_label",
            "project.create", "project.total", "project.delete.confirm.title", "project.delete.confirm.message",
            "quote.title", "quote.share_pdf", "quote.share_csv",
            "materials.custom", "settings.language", "settings.company_profile", "backup.export",
            "backup.import", "purchase.restore", "disclaimer.title", "error.invalid_pricing",
            "purchase.paywall.title", "purchase.paywall.buy_format", "purchase.paywall.footer",
            "error.invalid_currency", "error.web_too_thick", "price_book.title", "currency_change.title",
            "currency.selector.title", "currency.selector.search", "currency.selector.recent", "currency.selector.all",
            "profit_mode.markup", "profit_mode.margin", "price_source.manual", "price_source.history", "price_source.market_reference",
            "common.retry", "data.store_unavailable.title", "data.store_unavailable.message", "data.error.title",
            "delete.confirm.title", "delete.confirm.message", "quote.subtotal",
            "backup.import_copy_and_settings", "currency_change.failed.title"
        ]
        for language in AppLanguage.allCases.map(\.rawValue) {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in Set(dynamicKeys + fixedKeys) {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: nil, table: nil), key, "Missing \(key) in \(language)")
            }
        }
    }
}

@MainActor final class QuoteLanguageRegressionTests: XCTestCase {
    func testSelectedLanguageOverridesLegacyProjectForEveryStyleAndExport() throws {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: "app.language")
        defer { if let previous { defaults.set(previous, forKey: "app.language") } else { defaults.removeObject(forKey: "app.language") } }
        let source = try QuoteStyleSample.snapshot(language: "zh-Hans")
        let project = QuoteSnapshotRestorer.project(source)
        project.customerName = "客户原名"
        project.items[0].descriptionText = "客户规格备注"
        project.items[1].materialID = "custom-alloy"
        project.items[1].materialName = "自定义合金"
        for language in AppLanguage.allCases {
            defaults.set(language.rawValue, forKey: "app.language")
            let locale = Locale(identifier: language.rawValue)
            let expectedMaterial = MaterialCatalog.localizedName(materialID: "carbon-steel", fallback: "", locale: locale)
            let snapshot = try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: project))
            XCTAssertEqual(snapshot.quoteLanguage, language.rawValue)
            XCTAssertEqual(snapshot.lines[0].materialName, expectedMaterial)
            XCTAssertEqual(snapshot.lines[1].materialName, "自定义合金")
            XCTAssertEqual(snapshot.lines[0].descriptionText, "客户规格备注")
            XCTAssertEqual(snapshot.customerName, "客户原名")
            XCTAssertEqual(snapshot.totals.total, source.totals.total)
            XCTAssertEqual(project.quoteLanguage, "zh-Hans", "No migration of stored project data")
            let csv = try QuoteExportService.csvURL(for: project)
            defer { try? FileManager.default.removeItem(at: csv) }
            XCTAssertTrue(try String(contentsOf: csv, encoding: .utf8).contains(expectedMaterial))
            for style in QuoteStyle.allCases {
                project.quoteStyle = style
                let url = try QuoteExportService.pdfURL(for: project, company: nil)
                defer { try? FileManager.default.removeItem(at: url) }
                let text = try XCTUnwrap(PDFDocument(url: url)?.string)
                XCTAssertTrue(text.contains(AppLocalization.text("quote.title", locale: locale)), "\(language) / \(style): \(text)")
                XCTAssertTrue(text.contains(expectedMaterial), "\(language) / \(style)")
            }
        }
    }

    func testHistoricalQuoteRelocalizesWithoutChangingFrozenData() throws {
        let source = try QuoteStyleSample.snapshot(language: "zh-Hans")
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let original = try encoder.encode(source)
        for language in AppLanguage.allCases {
            let locale = Locale(identifier: language.rawValue)
            var localized = source.localized(for: locale)
            XCTAssertEqual(localized.quoteLanguage, language.rawValue)
            let url = try QuoteExportService.pdfURL(snapshot: localized)
            defer { try? FileManager.default.removeItem(at: url) }
            XCTAssertTrue(try XCTUnwrap(PDFDocument(url: url)?.string).contains(AppLocalization.text("quote.title", locale: locale)))
            let csv = String(decoding: QuoteCSVRenderer.data(localized, kind: .customer), as: UTF8.self)
            XCTAssertTrue(csv.contains(MaterialCatalog.localizedName(materialID: "carbon-steel", fallback: "", locale: locale)))
            localized.quoteLanguage = source.quoteLanguage
            for index in localized.lines.indices { localized.lines[index].materialName = source.lines[index].materialName }
            XCTAssertEqual(try encoder.encode(localized), original, "Only presentation language may change")
        }
        XCTAssertEqual(try encoder.encode(source), original)
    }

    func testSystemLanguageAndStyleSamplesUseResolvedLocale() throws {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: "app.language")
        defer { if let previous { defaults.set(previous, forKey: "app.language") } else { defaults.removeObject(forKey: "app.language") } }
        defaults.set("system", forKey: "app.language")
        let project = QuoteSnapshotRestorer.project(try QuoteStyleSample.snapshot(language: "ja"))
        let snapshot = try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: project))
        XCTAssertEqual(snapshot.quoteLanguage, AppLanguage.resolve(AppLocalization.systemLocale).rawValue)
        defaults.set("zh-Hans", forKey: "app.language")
        for language in AppLanguage.allCases {
            XCTAssertEqual(try QuoteStyleSample.snapshot(language: language.rawValue).quoteLanguage, language.rawValue)
        }
    }
}
