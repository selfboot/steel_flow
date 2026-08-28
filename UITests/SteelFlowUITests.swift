import XCTest

@MainActor
final class SteelFlowUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en", "-app.unitSystem", "metric"]
        app.launch()
        return app
    }

    func testCoreNavigationAndDefaultCalculation() {
        continueAfterFailure = false
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Calculate"].waitForExistence(timeout: 3))
        let plate = app.staticTexts["Plate / flat bar"]
        XCTAssertTrue(plate.exists)
        plate.tap()
        XCTAssertTrue(app.navigationBars["Plate / flat bar"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Total mass"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["47.1 kg"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.buttons["Save to project"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Save to project"].isEnabled)
    }

    func testAllPrimaryTabsRenderLocalizedContent() {
        continueAfterFailure = false
        let app = launchApp()
        app.tabBars.buttons["Projects"].tap()
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 2))
        app.tabBars.buttons["Materials"].tap()
        XCTAssertTrue(app.navigationBars["Materials"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Carbon steel"].waitForExistence(timeout: 2))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["App language"].exists)
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Data collection"].waitForExistence(timeout: 2))
    }
}
