import XCTest
@testable import SteelFlow

final class LocalizationTests: XCTestCase {
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
            "delete.confirm.title", "delete.confirm.message"
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
