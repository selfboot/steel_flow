import XCTest
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
            ("ja_JP", .japanese), ("ko_KR", .korean), ("fr_FR", .english)
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
        XCTAssertEqual(AppLocalization.text("quote.title", locale: Locale(identifier: "fr_FR")), "QUOTE")
    }

    func testSystemLanguageUsesFirstSupportedPreference() {
        XCTAssertEqual(AppLanguage.preferred(in: ["fr-FR", "ja-JP", "en-US"]), .japanese)
        XCTAssertEqual(AppLanguage.preferred(in: ["zh-TW", "en-US"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.preferred(in: ["zh-HK", "en-US"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.preferred(in: ["ko-KR", "en-US"]), .korean)
        XCTAssertEqual(AppLanguage.preferred(in: ["de-DE"]), .english)
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
