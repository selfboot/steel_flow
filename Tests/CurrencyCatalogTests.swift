import XCTest
@testable import SteelFlow

final class CurrencyCatalogTests: XCTestCase {
    func testCatalogContainsCurrentCommonCurrenciesWithoutDuplicates() {
        XCTAssertGreaterThan(CurrencyCatalog.allCodes.count, 100)
        XCTAssertTrue(CurrencyCatalog.allCodes.contains("USD"))
        XCTAssertTrue(CurrencyCatalog.allCodes.contains("CNY"))
        XCTAssertTrue(CurrencyCatalog.allCodes.contains("EUR"))
        XCTAssertEqual(CurrencyCatalog.allCodes.count, Set(CurrencyCatalog.allCodes).count)
    }

    func testRecentCurrencyMovesToFrontAndRemovesDuplicate() {
        let result = CurrencyCatalog.updatedRecent(
            selecting: "cny",
            existing: ["USD", "EUR", "CNY", "JPY"]
        )
        XCTAssertEqual(result, ["CNY", "USD", "EUR", "JPY"])
    }

    func testRecentCurrencyHistoryHonorsLimitAndRejectsInvalidCodes() {
        XCTAssertEqual(
            CurrencyCatalog.updatedRecent(selecting: "JPY", existing: ["USD", "CNY", "EUR"], limit: 3),
            ["JPY", "USD", "CNY"]
        )
        XCTAssertEqual(
            CurrencyCatalog.updatedRecent(selecting: "invalid", existing: ["USD", "CNY"], limit: 3),
            ["USD", "CNY"]
        )
    }

    func testRecentCurrencyStorageDeduplicatesAndNormalizes() {
        XCTAssertEqual(CurrencyCatalog.decodedRecent("usd,CNY,USD,bad"), ["USD", "CNY"])
    }
}
