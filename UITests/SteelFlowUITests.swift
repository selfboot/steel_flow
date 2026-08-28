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

    func testCaptureEnglishMarketingScreens() throws {
        try captureMarketingScreens(locale: "en-US", language: "en")
    }

    func testCaptureChineseMarketingScreens() throws {
        try captureMarketingScreens(locale: "zh-Hans", language: "zh-Hans")
    }

    private func captureMarketingScreens(locale: String, language: String) throws {
        continueAfterFailure = false
        let screens = ["home", "calculation", "pricing", "project", "quote", "materials"]
        for screen in screens {
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(\(language))",
                "-AppleLocale", locale == "zh-Hans" ? "zh_CN" : "en_US",
                "-app.language", language,
                "-app.unitSystem", "metric",
                "-app.currency", locale == "zh-Hans" ? "CNY" : "USD",
                "--marketing-screen", screen,
                "--marketing-locale", locale
            ]
            app.launch()
            try waitForMarketingScreen(screen, in: app, language: language)
            attachScreenshot(named: "\(locale)-\(screen)")
            app.terminate()
        }
    }

    private func waitForMarketingScreen(_ screen: String, in app: XCUIApplication, language: String) throws {
        let chinese = language == "zh-Hans"
        switch screen {
        case "home":
            XCTAssertTrue(app.navigationBars[chinese ? "计算" : "Calculate"].waitForExistence(timeout: 8))
        case "calculation":
            XCTAssertTrue(app.navigationBars[chinese ? "钢板 / 扁钢" : "Plate / flat bar"].waitForExistence(timeout: 8))
            let target = app.staticTexts[chinese ? "总重量" : "Total mass"]
            for _ in 0..<5 where !target.isHittable { app.swipeUp() }
            XCTAssertTrue(target.waitForExistence(timeout: 3))
        case "pricing":
            XCTAssertTrue(app.navigationBars[chinese ? "钢板 / 扁钢" : "Plate / flat bar"].waitForExistence(timeout: 8))
            let target = app.staticTexts[chinese ? "损耗" : "Waste"]
            for _ in 0..<3 where !target.isHittable { app.swipeUp() }
            XCTAssertTrue(target.waitForExistence(timeout: 3))
        case "project":
            XCTAssertTrue(app.navigationBars[chinese ? "港区雨棚" : "Harbor Canopy"].waitForExistence(timeout: 10))
            let total = app.staticTexts[chinese ? "总价" : "Total"]
            for _ in 0..<3 where !total.isHittable { app.swipeUp() }
        case "quote":
            XCTAssertTrue(app.navigationBars[chinese ? "报价预览" : "Quote preview"].waitForExistence(timeout: 10))
            let share = app.staticTexts[chinese ? "分享 PDF 报价单" : "Share PDF quote"]
            for _ in 0..<4 where !share.isHittable { app.swipeUp() }
            _ = share.waitForExistence(timeout: 5)
        case "materials":
            XCTAssertTrue(app.navigationBars[chinese ? "材料" : "Materials"].waitForExistence(timeout: 8))
            let priceBook = app.staticTexts[chinese ? "Q235B 华东现货" : "Q235B regional spot"]
            for _ in 0..<4 where !priceBook.isHittable { app.swipeUp() }
            XCTAssertTrue(priceBook.waitForExistence(timeout: 3))
        default:
            XCTFail("Unknown marketing screen: \(screen)")
        }
        usleep(500_000)
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
