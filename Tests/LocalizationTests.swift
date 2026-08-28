import XCTest
@testable import SteelFlow

final class LocalizationTests: XCTestCase {
    func testEnglishAndChineseHaveExactlyTheSameKeys() throws {
        func keys(for language: String) throws -> Set<String> {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let stringsPath = URL(fileURLWithPath: path).appendingPathComponent("Localizable.strings").path
            let dictionary = try XCTUnwrap(NSDictionary(contentsOfFile: stringsPath) as? [String: String])
            return Set(dictionary.keys)
        }
        XCTAssertEqual(try keys(for: "en"), try keys(for: "zh-Hans"))
    }

    func testDynamicLocalizationAndEnglishCountsHonorExplicitLocale() {
        XCTAssertEqual(AppLocalization.text("purchase.free", locale: Locale(identifier: "zh-Hans")), "免费版")
        XCTAssertEqual(AppLocalization.text("purchase.free", locale: Locale(identifier: "en")), "Free plan")
        XCTAssertEqual(AppLocalization.count("project.item_count", value: 1, locale: Locale(identifier: "en")), "1 item")
        XCTAssertEqual(AppLocalization.count("project.item_count", value: 2, locale: Locale(identifier: "en")), "2 items")
    }

    func testCriticalKeysExistInEnglishAndSimplifiedChinese() throws {
        let dynamicKeys =
            ProfileKind.allCases.map { "profile.\($0.rawValue)" } +
            DimensionField.allCases.map { "dimension.\($0.rawValue)" } +
            MaterialCatalog.presets.flatMap { [$0.nameKey, $0.noteKey] }
        let fixedKeys = [
            "tab.calculate", "tab.projects", "tab.materials", "tab.settings",
            "calculator.hero.title", "calculator.result.total_mass", "calculator.save_to_project",
            "project.create", "project.total", "quote.title", "quote.share_pdf", "quote.share_csv",
            "materials.custom", "settings.language", "settings.company_profile", "backup.export",
            "backup.import", "purchase.restore", "disclaimer.title", "error.invalid_pricing",
            "error.invalid_currency", "error.web_too_thick", "price_book.title", "currency_change.title",
            "profit_mode.markup", "profit_mode.margin", "price_source.manual", "price_source.history", "price_source.market_reference",
            "common.retry", "data.store_unavailable.title", "data.store_unavailable.message", "data.error.title",
            "delete.confirm.title", "delete.confirm.message", "quote.subtotal",
            "backup.import_copy_and_settings", "currency_change.failed.title"
        ]
        for language in ["en", "zh-Hans"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in Set(dynamicKeys + fixedKeys) {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: nil, table: nil), key, "Missing \(key) in \(language)")
            }
        }
    }
}
