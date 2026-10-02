import XCTest
import StoreKitTest

@MainActor
final class SteelFlowUITests: XCTestCase {
    private var storeKitSession: SKTestSession?

    private func configureStoreKit() throws {
        let configuration = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "SteelFlow", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: configuration)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = false
        storeKitSession = session
    }

    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en", "-app.unitSystem", "metric"] + extraArguments
        app.launch()
        return app
    }

    func testCoreNavigationAndDefaultCalculation() {
        continueAfterFailure = false
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Calculate"].waitForExistence(timeout: 3))
        let plate = app.descendants(matching: .any)["profile.plate"]
        XCTAssertTrue(plate.waitForExistence(timeout: 2))
        plate.tap()
        XCTAssertTrue(app.navigationBars["Plate / flat bar"].waitForExistence(timeout: 2))
        let totalMass = app.staticTexts["Total mass"].firstMatch
        for _ in 0..<8 where !totalMass.isHittable { app.swipeUp() }
        XCTAssertTrue(totalMass.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["47.1 kg"].firstMatch.waitForExistence(timeout: 2))
        let save = app.buttons["Save to project"]
        for _ in 0..<8 where !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(save.isEnabled)
    }

    func testLengthValueInputHasADistinctTapTargetAndAcceptsPreciseValues() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "-app.unitSystem", "metric", "--marketing-screen", "calculation",
            "--marketing-locale", "en-US", "--marketing-profile", "plate"
        ]
        app.launch()

        let valueField = app.textFields["length.value"]
        let unitPicker = app.descendants(matching: .any)["length.unit"]
        XCTAssertTrue(valueField.waitForExistence(timeout: 3))
        XCTAssertTrue(unitPicker.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(valueField.frame.height, 44)
        XCTAssertGreaterThanOrEqual(valueField.frame.width, 112)
        XCTAssertFalse(valueField.frame.intersects(unitPicker.frame), "Length value and unit must have distinct hit targets")
        XCTAssertGreaterThanOrEqual(unitPicker.frame.minY, valueField.frame.maxY, "Length unit must use its own row")

        valueField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        valueField.typeText("7")
        XCTAssertEqual(valueField.value as? String, "67", "First focus should put the cursor after the existing value")
        // Clear explicitly: double-tapping the center of a wide right-aligned field
        // can hit blank space instead of selecting the number on some iOS versions.
        valueField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2) + "7.25")
        XCTAssertEqual(valueField.value as? String, "7.25")
        attachScreenshot(named: "length-value-input-focused")
    }

    func testQuantitySupportsDirectEntryForLargeCounts() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "-app.unitSystem", "metric", "--marketing-screen", "calculation",
            "--marketing-locale", "en-US", "--marketing-profile", "plate"
        ]
        app.launch()

        let quantityField = app.textFields["quantity.value"]
        XCTAssertTrue(quantityField.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(quantityField.frame.height, 44)
        quantityField.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        quantityField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2) + "12500")
        XCTAssertEqual(quantityField.value as? String, "12500")
        app.buttons["Done"].tap()
        XCTAssertEqual(quantityField.value as? String, "12500")
        XCTAssertTrue(app.staticTexts["588,750 kg"].firstMatch.waitForExistence(timeout: 3), "The weight preview must reflect the new quantity")
        attachScreenshot(named: "quantity-direct-entry")
    }

    func testEveryProfilePreviewRendersEnteredLengthAndDimensions() {
        continueAfterFailure = false
        let profiles = [
            "plate", "roundBar", "squareBar", "hexBar", "octagonalBar", "roundTube", "squareTube",
            "rectangularTube", "angle", "channel", "iSection", "tSection", "customArea"
        ]

        for profile in profiles {
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
                "-app.unitSystem", "metric", "--marketing-screen", "calculation",
                "--marketing-locale", "en-US", "--marketing-profile", profile
            ]
            app.launch()

            let preview = app.descendants(matching: .any)["calculator.profile_preview"]
            if !preview.exists {
                let disclosure = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "3D profile preview")).firstMatch
                for _ in 0..<6 where !disclosure.isHittable { app.swipeUp() }
                XCTAssertTrue(disclosure.isHittable)
                disclosure.tap()
            }
            for _ in 0..<6 where !preview.isHittable { app.swipeUp() }
            XCTAssertTrue(preview.waitForExistence(timeout: 3), "Missing 3D preview for \(profile)")
            XCTAssertTrue(preview.isHittable, "3D preview is off-screen for \(profile)")
            XCTAssertTrue((preview.value as? String)?.contains("6 m") == true, "Missing length for \(profile)")
            attachScreenshot(named: "3d-profile-\(profile)")
            app.terminate()
        }
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

    func testCurrencySearchDisappearsAfterSelectingCurrency() {
        continueAfterFailure = false
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.staticTexts["Currency"].tap()

        XCTAssertTrue(app.navigationBars["Choose Currency"].waitForExistence(timeout: 3))
        let searchField = app.textFields["Search by currency or code"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("JPY")

        let yenCode = app.staticTexts["JPY"].firstMatch
        XCTAssertTrue(yenCode.waitForExistence(timeout: 3))
        yenCode.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertFalse(searchField.exists, "Currency search must be destroyed when leaving its page")
        XCTAssertFalse(app.staticTexts["Search by currency or code"].exists)
    }

    func testFeedbackEntryBuildsEmailAndOffersFallback() {
        continueAfterFailure = false
        let app = launchApp(extraArguments: ["--simulate-mail-unavailable"])

        app.tabBars.buttons["Settings"].tap()
        let feedbackEntry = app.buttons["Feedback & feature requests"]
        for _ in 0..<5 where !feedbackEntry.isHittable { app.swipeUp() }
        XCTAssertTrue(feedbackEntry.waitForExistence(timeout: 3))
        feedbackEntry.tap()

        XCTAssertTrue(app.navigationBars["Feedback"].waitForExistence(timeout: 3))
        let summary = app.textFields["Brief summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        summary.tap()
        summary.typeText("Test feedback")

        let send = app.buttons["Send feedback"]
        XCTAssertTrue(send.isEnabled)
        send.tap()

        XCTAssertTrue(app.buttons["Copy feedback content"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open email app"].exists)
    }

    func testLockedFeatureOpensPurchaseLandingPageWithStoreProduct() throws {
        continueAfterFailure = false
        try configureStoreKit()
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "-purchase.pro.cached", "NO"
        ]
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let companyProfile = app.buttons["Company profile"]
        XCTAssertTrue(companyProfile.waitForExistence(timeout: 5))
        companyProfile.tap()

        XCTAssertTrue(app.navigationBars["SteelFlow Pro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Unlock SteelFlow Pro"].exists)
        XCTAssertTrue(app.buttons["Restore purchase"].exists)

        let purchaseButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Unlock Pro ·")
        ).firstMatch
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 20), "The App Store product and localized price should load")
        XCTAssertTrue(purchaseButton.isEnabled, "A configured lifetime product must be purchasable")
        attachScreenshot(named: "pro-purchase-landing-page")
    }

    func testPurchaseInvokesStoreKitAndCancellationIsHandledCleanly() throws {
        continueAfterFailure = false
        try configureStoreKit()
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "-purchase.pro.cached", "NO"
        ]
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        app.buttons["Company profile"].tap()

        let purchaseButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Unlock Pro ·")
        ).firstMatch
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 20))
        XCTAssertTrue(purchaseButton.isEnabled)
        purchaseButton.tap()

        let systemProcesses = [
            XCUIApplication(bundleIdentifier: "com.apple.ios.StoreKitUIService"),
            XCUIApplication(bundleIdentifier: "com.apple.StoreKitUISceneService"),
            XCUIApplication(bundleIdentifier: "com.apple.AMSUIAuthenticationViewService"),
            XCUIApplication(bundleIdentifier: "com.apple.springboard")
        ]
        let cancelPredicate = NSPredicate(format: "label IN %@", ["Cancel", "取消"])
        let deadline = Date().addingTimeInterval(10)
        var cancelButton: XCUIElement?
        repeat {
            cancelButton = systemProcesses
                .map { $0.buttons.matching(cancelPredicate).firstMatch }
                .first(where: \.exists)
            if cancelButton == nil { Thread.sleep(forTimeInterval: 0.25) }
        } while cancelButton == nil && Date() < deadline

        let systemCancel = try? XCTUnwrap(cancelButton, "Tapping purchase should invoke Apple's StoreKit confirmation UI")
        systemCancel?.tap()

        XCTAssertTrue(app.navigationBars["SteelFlow Pro"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts["Purchase unavailable"].exists, "User cancellation should not be reported as an error")
    }

    func testCalculatorRemainsUsableAtLargestAccessibilityTextSize() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "-app.unitSystem", "metric", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        let plate = app.descendants(matching: .any)["profile.plate"]
        for _ in 0..<4 where !plate.isHittable { app.swipeUp() }
        XCTAssertTrue(plate.waitForExistence(timeout: 3))
        XCTAssertTrue(plate.isHittable)
        plate.tap()

        XCTAssertTrue(app.navigationBars["Plate / flat bar"].waitForExistence(timeout: 3))
        let width = app.textFields["dimension.width"]
        for _ in 0..<12 where !width.isHittable { app.swipeUp() }
        XCTAssertTrue(width.isHittable, "Width input must remain reachable at the largest text size")
        width.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        attachScreenshot(named: "accessibility-xxxl-calculator")
    }

    func testChineseQuoteSummaryAndPDFRemainAccessibleOnCompactPhone() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--workflow-tests", "--workflow-free",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "zh-Hans",
            "-app.unitSystem", "metric", "-app.currency", "CNY",
            "--marketing-screen", "quote", "--marketing-locale", "zh-Hans"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["报价预览"].waitForExistence(timeout: 8))
        let title = app.staticTexts["总价、¥35,228.94"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(title.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(title.frame.maxX, app.windows.firstMatch.frame.maxX)
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        attachScreenshot(named: "compact-chinese-quote")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "打开 PDF 预览")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["生成的 PDF"].waitForExistence(timeout: 3))
    }

    func testEnglishQuoteSummaryAndPDFRemainAccessibleOnCompactPhone() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--workflow-tests", "--workflow-free",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "quote", "--marketing-locale", "en-US"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Quote preview"].waitForExistence(timeout: 8))
        let title = app.staticTexts["Total, $5,015.25"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertLessThanOrEqual(title.frame.maxX, app.windows.firstMatch.frame.maxX)
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        attachScreenshot(named: "compact-english-quote")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Open PDF preview")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Generated PDF"].waitForExistence(timeout: 3))
    }

    func testChineseProjectSummaryKeepsLongLabelsAndValuesReadable() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-app.language", "zh-Hans",
            "--marketing-screen", "project", "--marketing-locale", "zh-Hans"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["港区雨棚"].waitForExistence(timeout: 8))
        let breakdown = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "费用明细")).firstMatch
        for _ in 0..<4 where !breakdown.isHittable { app.swipeUp() }
        XCTAssertTrue(breakdown.isHittable)
        breakdown.tap()
        let label = app.staticTexts["加工及其他费用"]
        let amount = app.staticTexts["¥2,280.00"]
        for _ in 0..<4 where !label.isHittable { app.swipeUp() }
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        XCTAssertFalse(label.frame.intersects(amount.frame))
        XCTAssertLessThanOrEqual(amount.frame.maxX, app.windows.firstMatch.frame.maxX)
        attachScreenshot(named: "compact-chinese-project-summary")
    }

    func testQuoteSummaryUsesProjectCurrencyWithEnglishAppLanguage() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--workflow-tests", "--workflow-free",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "quote", "--marketing-locale", "zh-Hans"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Quote preview"].waitForExistence(timeout: 8))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency; formatter.currencyCode = "CNY"; formatter.locale = Locale(identifier: "en")
        let amount = formatter.string(from: NSDecimalNumber(string: "35228.94"))!
        let total = app.staticTexts["Total, " + amount]
        XCTAssertTrue(total.waitForExistence(timeout: 3))
        let document = app.staticTexts["quote.rendered_text"]
        XCTAssertTrue(document.waitForExistence(timeout: 3))
        XCTAssertTrue((document.value as? String)?.contains("QUOTE") == true)
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        XCTAssertFalse(app.staticTexts["Material subtotal"].exists)
        XCTAssertFalse(app.staticTexts["Markup"].exists)
        attachScreenshot(named: "quote-language-and-customer-safe-pricing")
    }

    func testPriceDeletionRequiresExplicitConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--workflow-tests", "--workflow-free",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "materials", "--marketing-locale", "en-US"
        ]
        app.launch()

        app.buttons["Saved price history"].tap()
        let price = app.staticTexts["Q235B regional spot"].firstMatch
        for _ in 0..<4 where !price.isHittable { app.swipeUp() }
        XCTAssertTrue(price.waitForExistence(timeout: 5))
        price.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this item?"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(price.exists)
    }

    func testDataStoreFailureShowsRecoveryInsteadOfCrashing() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--simulate-data-store-failure"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["SteelFlow Data Is Unavailable"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Try Again"].exists)
    }

    func testProjectItemDeletionRequiresExplicitConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "project", "--marketing-locale", "en-US"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Harbor Canopy"].waitForExistence(timeout: 8))
        let item = app.staticTexts["Base plate 200 × 12"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this item?"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(item.exists)
    }

    func testProjectDeletionRequiresConfirmationAndCannotBeRestored() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "projects", "--marketing-locale", "en-US"
        ]
        app.launch()

        let project = app.staticTexts["Harbor Canopy"]
        XCTAssertTrue(project.waitForExistence(timeout: 8))
        project.swipeLeft()
        XCTAssertTrue(app.buttons["Archive"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Delete"].exists)
        app.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["Delete this project?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["The project and all its items will be permanently deleted. This cannot be undone."].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(project.exists)

        project.swipeLeft()
        app.buttons["Delete"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(project.waitForNonExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Restore"].exists)
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
            dismissSimulatorAccountPrompt()
            try waitForMarketingScreen(screen, in: app, language: language)
            dismissSimulatorAccountPrompt()
            attachScreenshot(named: "\(locale)-\(screen)")
            app.terminate()
        }
    }

    private func dismissSimulatorAccountPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.exists {
            let postpone = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Not Now", "以后", "稍后", "暂不"])).firstMatch
            if postpone.exists { postpone.tap() }
        }
        XCTAssertFalse(alert.exists, "Marketing captures must not contain a system alert")
    }

    private func waitForMarketingScreen(_ screen: String, in app: XCUIApplication, language: String) throws {
        let chinese = language == "zh-Hans"
        switch screen {
        case "home":
            XCTAssertTrue(app.navigationBars[chinese ? "计算" : "Calculate"].waitForExistence(timeout: 8))
        case "calculation":
            XCTAssertTrue(app.navigationBars[chinese ? "钢板 / 扁钢" : "Plate / flat bar"].waitForExistence(timeout: 8))
            let target = app.staticTexts["847.8 kg"].firstMatch
            XCTAssertTrue(target.waitForExistence(timeout: 3))
            XCTAssertTrue(target.isHittable, "Weight preview must be visible before scrolling")
        case "pricing":
            XCTAssertTrue(app.navigationBars[chinese ? "钢板 / 扁钢" : "Plate / flat bar"].waitForExistence(timeout: 8))
            let pricingTitle = chinese ? "计价" : "Pricing"
            let disclosure = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@", pricingTitle, pricingTitle + ",", pricingTitle + "、")).firstMatch
            for _ in 0..<4 where !disclosure.isHittable { app.swipeUp() }
            XCTAssertTrue(disclosure.isHittable)
            disclosure.tap()
            let target = app.staticTexts[chinese ? "损耗" : "Waste"]
            for _ in 0..<3 where !target.isHittable { app.swipeUp() }
            XCTAssertTrue(target.waitForExistence(timeout: 3))
            let price = app.textFields["calculator.price_input"]
            for _ in 0..<3 where !price.isHittable { app.swipeUp() }
            XCTAssertTrue(price.isHittable)
        case "project":
            XCTAssertTrue(app.navigationBars[chinese ? "港区雨棚" : "Harbor Canopy"].waitForExistence(timeout: 10))
            let total = app.staticTexts[chinese ? "总价" : "Total"]
            for _ in 0..<3 where !total.isHittable { app.swipeUp() }
        case "quote":
            XCTAssertTrue(app.navigationBars[chinese ? "报价预览" : "Quote preview"].waitForExistence(timeout: 10))
            let share = app.buttons[chinese ? "保存版本并分享 PDF" : "Save version & share PDF"].firstMatch
            XCTAssertTrue(share.waitForExistence(timeout: 5))
        case "materials":
            XCTAssertTrue(app.navigationBars[chinese ? "材料" : "Materials"].waitForExistence(timeout: 8))
            let builtIn = app.staticTexts[chinese ? "碳钢" : "Carbon steel"].firstMatch
            XCTAssertTrue(builtIn.waitForExistence(timeout: 3))
            XCTAssertTrue(builtIn.isHittable, "Capture the material catalog before switching to saved prices")
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

@MainActor
final class LocalizationUITests: XCTestCase {
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTraditionalChineseSystemLanguageAndQuote() {
        verifyLanguage("zh-Hant", region: "zh_TW", native: "繁體中文", calculate: "計算", settings: "設定", projects: "專案", create: "新建專案", cancel: "取消", projectSettings: "專案設定", save: "完成", preview: "報價預覽")
    }

    func testJapaneseSystemLanguageAndQuote() {
        verifyLanguage("ja", region: "ja_JP", native: "日本語", calculate: "計算", settings: "設定", projects: "プロジェクト", create: "新規プロジェクト", cancel: "キャンセル", projectSettings: "プロジェクト設定", save: "完了", preview: "見積書プレビュー")
    }

    func testKoreanSystemLanguageAndQuote() {
        verifyLanguage("ko", region: "ko_KR", native: "한국어", calculate: "계산", settings: "설정", projects: "프로젝트", create: "새 프로젝트", cancel: "취소", projectSettings: "프로젝트 설정", save: "완료", preview: "견적서 미리보기")
    }

    func testGermanSystemLanguageAndQuote() {
        verifyLanguage("de", region: "de_DE", native: "Deutsch", calculate: "Berechnen", settings: "Einstellungen", projects: "Projekte", create: "Neues Projekt", cancel: "Abbrechen", projectSettings: "Projekteinstellungen", save: "Fertig", preview: "Angebotsvorschau")
    }

    func testSpanishSystemLanguageAndQuote() {
        verifyLanguage("es", region: "es_ES", native: "Español", calculate: "Calcular", settings: "Ajustes", projects: "Proyectos", create: "Nuevo proyecto", cancel: "Cancelar", projectSettings: "Ajustes del proyecto", save: "Listo", preview: "Vista del presupuesto")
    }

    func testFrenchSystemLanguageAndQuote() {
        verifyLanguage("fr", region: "fr_FR", native: "Français", calculate: "Calculer", settings: "Réglages", projects: "Projets", create: "Nouveau projet", cancel: "Annuler", projectSettings: "Réglages du projet", save: "Terminé", preview: "Aperçu du devis")
    }

    private func verifyLanguage(_ language: String, region: String, native: String, calculate: String, settings: String, projects: String, create: String, cancel: String, projectSettings: String, save: String, preview: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "--ui-legacy-chinese-quote", "-AppleLanguages", "(\(language))", "-AppleLocale", region, "-app.language", "system", "-app.unitSystem", "metric"]
        app.launch()
        XCTAssertTrue(app.navigationBars[calculate].waitForExistence(timeout: 8))
        capture("1.3-\(language)-home-light")
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.textFields["length.value"].waitForExistence(timeout: 3))
        capture("1.3-\(language)-calculation-light")
        app.tabBars.buttons[settings].tap()
        XCTAssertTrue(app.buttons["settings.language"].waitForExistence(timeout: 3))
        capture("1.3-\(language)-settings-light")
        app.tabBars.buttons[projects].tap()
        app.buttons["projects.menu"].tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", create, "projects.menu")).firstMatch.tap()
        let languagePicker = app.buttons["project.quoteLanguage"]
        XCTAssertTrue(app.navigationBars[create].waitForExistence(timeout: 3))
        XCTAssertFalse(languagePicker.exists, "Quote language follows the app setting")
        capture("1.3-\(language)-new-project")
        app.buttons[cancel].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        app.buttons["project.menu"].tap()
        app.buttons[projectSettings].tap()
        XCTAssertTrue(app.navigationBars.buttons[save].waitForExistence(timeout: 3))
        XCTAssertFalse(languagePicker.exists)
        app.buttons[save].tap()
        app.buttons[preview].tap()
        XCTAssertTrue(app.navigationBars[preview].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        let document = app.staticTexts["quote.rendered_text"]
        XCTAssertTrue(document.waitForExistence(timeout: 5))
        let titles = ["zh-Hant": "報價單", "ja": "見積書", "ko": "견적서", "de": "ANGEBOT", "es": "PRESUPUESTO", "fr": "DEVIS"]
        XCTAssertTrue((document.value as? String)?.contains(titles[language]!) == true, document.debugDescription)
        capture("1.3-\(language)-quote-light")
        app.terminate()

        app.launchArguments += ["--ui-dark"]
        app.launch()
        XCTAssertTrue(app.navigationBars[calculate].waitForExistence(timeout: 5))
        capture("1.3-\(language)-home-dark")
        app.tabBars.buttons[settings].tap()
        XCTAssertTrue(app.buttons["settings.language"].waitForExistence(timeout: 3))
        capture("1.3-\(language)-settings-dark")
        app.terminate()
    }

    func testGermanExistingItemPricesSurviveEditingAndHistorySelection() {
        verifyExistingItemPrices("de", projects: "Projekte", fees: "Zusätzliche Kosten", details: "Lieferant und Preisquelle", history: "Gespeicherte Preise")
    }

    func testSpanishExistingItemPricesSurviveEditingAndHistorySelection() {
        verifyExistingItemPrices("es", projects: "Proyectos", fees: "Gastos adicionales", details: "Proveedor y fuente del precio", history: "Historial de precios")
    }

    func testFrenchExistingItemPricesSurviveEditingAndHistorySelection() {
        verifyExistingItemPrices("fr", projects: "Projets", fees: "Frais supplémentaires", details: "Fournisseur et source du prix", history: "Historique des prix")
    }

    private func verifyExistingItemPrices(_ language: String, projects: String, fees: String, details: String, history: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "--ui-item-decimal-values", "-AppleLanguages", "(\(language))", "-AppleLocale", language, "-app.language", language, "-app.unitSystem", "metric"]
        app.launch()
        defer { app.terminate() }
        func reveal(_ element: XCUIElement, upwards: Bool = true) {
            for _ in 0..<12 where !element.isHittable {
                if upwards { app.swipeUp() } else { app.swipeDown() }
            }
            XCTAssertTrue(element.isHittable, element.debugDescription)
        }
        app.tabBars.buttons[projects].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        for round in 0..<3 {
            let item = app.staticTexts["Steel tube"].firstMatch
            reveal(item); item.tap()
            let navigation = app.navigationBars.firstMatch
            XCTAssertTrue(navigation.buttons["item.done"].waitForExistence(timeout: 5))
            let price = app.textFields["item.unit_price"]
            reveal(price)
            let cancel = ["de": "Abbrechen", "es": "Cancelar", "fr": "Annuler"][language]!
            XCTAssertFalse(navigation.buttons[cancel].exists, "The pushed editor must not duplicate the native back button")
            XCTAssertEqual(navigation.buttons.count, 2, "Keep native back and Done available")
            if round == 0 { capture("existing-item-\(language)-navigation") }
            XCTAssertEqual(price.value as? String, round < 2 ? "2,345" : "4,567")
            let feesDisclosure = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", fees, fees + ",")).firstMatch
            reveal(feesDisclosure); feesDisclosure.tap()
            let processing = app.textFields["item.processing_fee"]
            let other = app.textFields["item.other_fee"]
            reveal(processing); XCTAssertEqual(processing.value as? String, "1,25")
            reveal(other); XCTAssertEqual(other.value as? String, "0,125")
            if round == 1 {
                let sourceDisclosure = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", details, details + ",")).firstMatch
                reveal(sourceDisclosure); sourceDisclosure.tap()
                let source = app.buttons["item.price_source"]
                reveal(source); source.tap()
                app.buttons[history].tap()
                let savedPrice = app.buttons["item.saved_price"]
                reveal(savedPrice); savedPrice.tap()
                app.buttons["Replacement price"].tap()
                reveal(price, upwards: false)
                XCTAssertEqual(price.value as? String, "4,567", "Selecting a stored price must format its decimal separator before parsing")
            }
            let done = app.buttons["item.done"]
            XCTAssertTrue(done.isEnabled, "Opening an existing item must not invalidate its fees")
            capture("existing-item-\(language)-round-\(round)")
            done.tap()
            XCTAssertTrue(app.buttons["project.menu"].waitForExistence(timeout: 3))
        }
    }

    func testGermanEditingAndPaywall() {
        verifyEuropeanEditing("de", settings: "Einstellungen", projects: "Projekte", materials: "Materialien", projectSettings: "Projekteinstellungen", done: "Fertig", save: "Speichern", history: "Gespeicherte Preise", restore: "Kauf wiederherstellen")
    }

    func testSpanishEditingAndPaywall() {
        verifyEuropeanEditing("es", settings: "Ajustes", projects: "Proyectos", materials: "Materiales", projectSettings: "Ajustes del proyecto", done: "Listo", save: "Guardar", history: "Historial de precios", restore: "Restaurar compra")
    }

    func testFrenchEditingAndPaywall() {
        verifyEuropeanEditing("fr", settings: "Réglages", projects: "Projets", materials: "Matériaux", projectSettings: "Réglages du projet", done: "Terminé", save: "Enregistrer", history: "Historique des prix", restore: "Restaurer l’achat")
    }

    private func verifyEuropeanEditing(_ language: String, settings: String, projects: String, materials: String, projectSettings: String, done: String, save: String, history: String, restore: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let arguments = ["--workflow-tests", "--reset-workflow", "--ui-decimal-values", "-AppleLanguages", "(\(language))", "-AppleLocale", language, "-app.language", language, "-app.unitSystem", "metric", "-app.currency", "CNY"]
        app.launchArguments = arguments
        app.launch()
        func reveal(_ element: XCUIElement) {
            for _ in 0..<12 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable, element.debugDescription)
        }
        app.tabBars.buttons[projects].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        for _ in 0..<2 {
            app.buttons["project.menu"].tap(); app.buttons[projectSettings].tap()
            let tax = app.textFields["project.tax"]
            reveal(tax)
            XCTAssertEqual(tax.value as? String, "0,125")
            XCTAssertEqual(app.textFields["project.profit"].value as? String, "7,5")
            capture("europe-\(language)-project-pricing")
            app.buttons[done].tap()
        }
        app.tabBars.buttons[materials].tap()
        app.segmentedControls.buttons[history].tap()
        for _ in 0..<2 {
            app.staticTexts["Precision price"].firstMatch.tap()
            let price = app.textFields["price_book.price"]
            reveal(price)
            XCTAssertEqual(price.value as? String, "2,345")
            capture("europe-\(language)-saved-price")
            app.buttons[save].tap()
        }
        app.tabBars.buttons.element(boundBy: 0).tap()
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3))
        let materialName = ["de": "Kohlenstoffstahl", "es": "Acero al carbono", "fr": "Acier au carbone"][language]!
        let stainlessName = ["de": "Edelstahl 304", "es": "Acero inoxidable 304", "fr": "Acier inoxydable 304"][language]!
        let chooser = app.buttons["material.chooser"]
        XCTAssertTrue(chooser.label.contains(materialName))
        chooser.tap(); app.buttons[stainlessName].tap()
        XCTAssertTrue(chooser.label.contains(stainlessName))
        chooser.tap(); app.buttons[materialName].tap()
        capture("europe-\(language)-material-name")
        let length = app.textFields["length.value"]
        reveal(length)
        length.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        length.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8) + "0")
        app.buttons[done].tap()
        XCTAssertFalse(app.buttons["calculator.save"].isEnabled)
        capture("europe-\(language)-invalid-input")
        length.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        length.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8) + "6,125")
        app.buttons[done].tap()
        XCTAssertTrue(app.staticTexts["48,081 kg"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["calculator.save"].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        XCTAssertTrue(app.buttons["calculator.save"].waitForExistence(timeout: 3))
        app.tabBars.buttons[projects].tap()
        let savedProfile = app.staticTexts[["de": "Blech / Flachstahl", "es": "Placa / barra plana", "fr": "Tôle / plat"][language]!].firstMatch
        reveal(savedProfile)
        XCTAssertTrue(savedProfile.exists, "Saved calculation must appear in the project")
        capture("europe-\(language)-saved-calculation")
        app.terminate()

        for dark in [false, true] {
            app.launchArguments = arguments + ["--workflow-free"] + (dark ? ["--ui-dark"] : [])
            app.launch()
            app.tabBars.buttons[settings].tap()
            app.buttons["settings.membership"].tap()
            XCTAssertTrue(app.navigationBars["SteelFlow Pro"].waitForExistence(timeout: 4))
            capture("europe-\(language)-paywall-\(dark ? "dark" : "light")")
            let detail = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "PDF", "SteelFlow")).firstMatch
            reveal(detail)
            XCTAssertTrue(detail.exists)
            reveal(app.buttons[restore])
            capture("europe-\(language)-paywall-details-\(dark ? "dark" : "light")")
            app.terminate()
        }
    }

    func testGermanCalculatorAtLargestTextSize() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE", "-app.language", "de", "-app.unitSystem", "metric", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        let length = app.textFields["length.value"]
        for _ in 0..<12 where !length.isHittable { app.swipeUp() }
        XCTAssertTrue(length.isHittable)
        XCTAssertTrue(app.buttons["calculator.save"].isEnabled)
        capture("europe-de-accessibility-xxxl")
        app.terminate()
    }

    func testLanguageSwitchPreservesActiveCalculationAndSavedDraft() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_DE", "-app.unitSystem", "metric"]
        app.launch()
        func chooseLanguage(_ name: String) {
            app.tabBars.buttons.element(boundBy: 3).tap()
            app.buttons["settings.language"].tap()
            app.buttons[name].tap()
            let back = app.navigationBars.buttons["BackButton"]
            if back.exists { back.tap() }
            app.tabBars.buttons.element(boundBy: 0).tap()
        }
        // Establish a comma-decimal locale without overriding the app's language setting.
        chooseLanguage("English")
        chooseLanguage("System default")
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3), "Fresh defaults must also use the system number format")
        for name in ["日本語", "한국어", "繁體中文", "Deutsch", "Español", "Français", "English"] {
            chooseLanguage(name)
            let expected = ["Deutsch", "Español", "Français"].contains(name) ? "47,1 kg" : "47.1 kg"
            XCTAssertTrue(app.staticTexts[expected].firstMatch.waitForExistence(timeout: 3), "Weight must remain unchanged in \(name)")
        }
        chooseLanguage("System default")
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3))
        capture("1.3-locale-switch-preserves-weight")
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-workflow" }
        app.launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3), "Saved draft must retain the correct values and locale after relaunch")
        chooseLanguage("English")
        app.terminate()
    }

    func testSavedPriceReselectionAndUndoAfterResetPreservePricing() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "--ui-decimal-values", "-AppleLanguages", "(en)", "-AppleLocale", "en_DE", "-app.language", "system", "-app.unitSystem", "metric", "-app.currency", "CNY"]
        app.launch()
        func reveal(_ element: XCUIElement, upwards: Bool = true) {
            for _ in 0..<12 where !element.isHittable {
                if upwards { app.swipeUp() } else { app.swipeDown() }
            }
            XCTAssertTrue(element.exists)
            XCTAssertTrue(element.isHittable)
        }
        func chooseSavedPrice() {
            let source = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manual supplier price")).firstMatch
            reveal(source); source.tap()
            app.buttons["Saved price history"].tap()
            let chooser = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Choose a saved price")).firstMatch
            reveal(chooser); chooser.tap()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Precision price")).firstMatch.tap()
        }
        app.descendants(matching: .any)["profile.plate"].tap()
        let pricing = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", "Pricing", "Pricing,")).firstMatch
        reveal(pricing); pricing.tap()
        let details = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Supplier & source")).firstMatch
        reveal(details); details.tap()
        chooseSavedPrice()
        let price = app.textFields["calculator.price_input"]
        reveal(price, upwards: false)
        XCTAssertEqual(price.value as? String, "2,345")
        app.buttons["calculator.menu"].tap(); app.buttons["Start a fresh calculation"].tap()
        chooseSavedPrice()
        reveal(price, upwards: false)
        XCTAssertEqual(price.value as? String, "2,345", "The same saved price must apply after reset")

        // Undo must restore a manually adjusted historical price, not reload its original value.
        price.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        price.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8) + "4,567")
        app.buttons["Done"].tap()
        XCTAssertEqual(price.value as? String, "4,567")
        app.buttons["calculator.menu"].tap(); app.buttons["Start a fresh calculation"].tap()
        let undo = app.buttons["Undo last change"]
        reveal(undo, upwards: false); undo.tap()
        reveal(price)
        XCTAssertEqual(price.value as? String, "4,567", "Undo must preserve the adjusted value")
        let selection = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Precision price")).firstMatch
        reveal(selection)
        XCTAssertTrue(selection.exists, "Undo must restore the historical price selection")
        app.terminate()
    }

    func testResetKeepsValidDefaultCalculationInGermanRegion() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_DE", "-app.language", "system", "-app.unitSystem", "metric"]
        app.launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["calculator.menu"].tap()
        app.buttons["Start a fresh calculation"].tap()
        XCTAssertTrue(app.staticTexts["47,1 kg"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["calculator.save"].isEnabled)
        app.terminate()
    }

    func testEditingSavedRatesAndPricesInGermanRegionPreservesValues() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "--ui-decimal-values", "-AppleLanguages", "(en)", "-AppleLocale", "en_DE", "-app.language", "system", "-app.unitSystem", "metric"]
        app.launch()
        app.tabBars.buttons["Projects"].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        for _ in 0..<2 {
            app.buttons["project.menu"].tap()
            app.buttons["Project settings"].tap()
            let tax = app.textFields["project.tax"]
            for _ in 0..<8 where !tax.isHittable { app.swipeUp() }
            XCTAssertEqual(tax.value as? String, "0,125")
            XCTAssertEqual(app.textFields["project.profit"].value as? String, "7,5")
            XCTAssertTrue(app.buttons["Done"].isEnabled)
            app.buttons["Done"].tap()
        }
        app.tabBars.buttons["Materials"].tap()
        app.segmentedControls.buttons["Saved price history"].tap()
        for _ in 0..<2 {
            app.staticTexts["Precision price"].firstMatch.tap()
            let price = app.textFields["price_book.price"]
            for _ in 0..<8 where !price.isHittable { app.swipeUp() }
            XCTAssertEqual(price.value as? String, "2,345")
            XCTAssertTrue(app.buttons["Save"].isEnabled)
            app.buttons["Save"].tap()
        }
        app.terminate()
    }

    func testManualLanguageSwitchRelocalizesLegacyQuoteAndHistory() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "--ui-legacy-chinese-quote", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch(); defer { app.terminate() }
        let cases = [
            ("简体中文", "报价预览", "报价单", "完成", "历史报价"),
            ("繁體中文", "報價預覽", "報價單", "完成", "歷史報價"),
            ("日本語", "見積書プレビュー", "見積書", "完了", "見積書の履歴"),
            ("한국어", "견적서 미리보기", "견적서", "완료", "견적 이력"),
            ("Deutsch", "Angebotsvorschau", "ANGEBOT", "Fertig", "Angebotsverlauf"),
            ("Español", "Vista del presupuesto", "PRESUPUESTO", "Listo", "Historial de presupuestos"),
            ("Français", "Aperçu du devis", "DEVIS", "Terminé", "Historique des devis"),
            ("English", "Quote preview", "QUOTE", "Done", "Quote history")
        ]
        for (native, preview, pdfTitle, done, history) in cases {
            app.tabBars.buttons.element(boundBy: 3).tap()
            app.buttons["settings.language"].tap()
            app.buttons[native].tap()
            let back = app.navigationBars.buttons["BackButton"]
            if back.exists { back.tap() }
            app.tabBars.buttons.element(boundBy: 1).tap()
            let project = app.staticTexts["Workflow Quote"].firstMatch
            if !app.buttons["project.menu"].exists { project.tap() }
            app.buttons[preview].tap()
            let document = app.staticTexts["quote.rendered_text"]
            XCTAssertTrue(document.waitForExistence(timeout: 8))
            XCTAssertTrue((document.value as? String)?.contains(pdfTitle) == true, "\(native): \(document.debugDescription)")
            capture("language-switch-pdf-" + native)
            app.navigationBars.buttons[done].tap()
            app.buttons["project.menu"].tap()
            app.buttons[history].tap()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "v1 · ")).firstMatch.tap()
            let frozen = app.staticTexts["quote.history_rendered_text"]
            XCTAssertTrue(frozen.waitForExistence(timeout: 8))
            XCTAssertTrue((frozen.value as? String)?.contains(pdfTitle) == true, "Historical PDF: \(native)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.navigationBars.buttons[done].tap()
        }
    }

    func testManualLanguageSwitchUpdatesUIAndPersists() {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Do not override app.language in the launch domain: user changes must persist.
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.tabBars.buttons.element(boundBy: 3).tap()
        for (native, title) in [("繁體中文", "設定"), ("日本語", "設定"), ("한국어", "설정"), ("Deutsch", "Einstellungen"), ("Español", "Ajustes"), ("Français", "Réglages"), ("English", "Settings")] {
            let picker = app.buttons["settings.language"]
            XCTAssertTrue(picker.waitForExistence(timeout: 3))
            picker.tap()
            app.buttons[native].tap()
            let back = app.navigationBars.buttons["BackButton"]
            if back.exists { back.tap() }
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 3))
            XCTAssertTrue(picker.label.contains(native) || (picker.value as? String)?.contains(native) == true)
            capture("1.3-manual-" + native)
        }
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["Calculate"].waitForExistence(timeout: 5), "Manual language survives relaunch")
        app.terminate()
    }
}

@MainActor final class QuoteStyleUITests: XCTestCase {
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        for _ in 0..<12 where !element.isHittable {
            if up { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.isHittable)
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testPreviewStartsWithDefaultAndStyleChangesResetSavedVersion() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en", "-app.quoteStyle", "classic"]
        app.launch(); defer { app.terminate() }
        app.tabBars.buttons["Projects"].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        app.buttons["project.menu"].tap(); app.buttons["Project settings"].tap()
        let notes = app.descendants(matching: .any)["project.notes"].firstMatch
        reveal(notes, in: app)
        XCTAssertFalse(app.buttons["project.quoteStyle"].exists)
        XCTAssertFalse(app.textFields["Terms"].exists)
        capture("quote-project-settings-clean")
        app.navigationBars.buttons["Done"].tap()
        app.buttons["Quote preview"].tap()
        let choose = app.buttons["quote.style.choose"]
        XCTAssertTrue(choose.waitForExistence(timeout: 5)); XCTAssertTrue(choose.label.contains("Classic"), "New previews start with the global default")
        choose.tap()
        let forest = app.buttons["quote.style.forest"]
        reveal(forest, in: app); capture("styles-gallery-light-lower"); forest.tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 3)); XCTAssertTrue(choose.label.contains("Forest"))
        capture("styles-preview-forest-light")
        let more = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Other export options")).firstMatch
        reveal(more, in: app); more.tap()
        let save = app.buttons["quote.save_version"]
        reveal(save, in: app); save.tap()
        XCTAssertTrue(app.buttons["quote.save_share"].label.contains("Share PDF"))
        let openPDF = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Open PDF preview")).firstMatch
        reveal(openPDF, in: app, up: false); openPDF.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["quote.save_share"].label.contains("Share PDF"), "Returning from full-screen PDF must keep the saved version")
        reveal(choose, in: app, up: false); choose.tap()
        let minimal = app.buttons["quote.style.minimal"]
        reveal(minimal, in: app); minimal.tap()
        XCTAssertTrue(app.buttons["quote.save_share"].label.contains("Save version"), "A changed style must create a new frozen version")
        app.navigationBars.buttons["Done"].tap()
        app.buttons["Quote preview"].tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 5)); XCTAssertTrue(choose.label.contains("Classic"), "Reopening starts a new preview using the default")
        capture("styles-preview-default-on-reopen")
    }
    func testQuoteSettingsDoNotOfferRemovedTermsForFreeOrPro() {
        continueAfterFailure = false
        let app = XCUIApplication()
        for free in [false, true] {
            app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en"]
            if free { app.launchArguments.append("--workflow-free") }
            app.launch()
            app.tabBars.buttons["Projects"].tap()
            app.staticTexts["Workflow Quote"].firstMatch.tap()
            app.buttons["project.menu"].tap(); app.buttons["Project settings"].tap()
            let notes = app.descendants(matching: .any)["project.notes"].firstMatch
            reveal(notes, in: app)
            XCTAssertFalse(app.textFields["Terms"].exists)
            XCTAssertFalse(app.buttons["Custom quote terms require SteelFlow Pro."].exists)
            XCTAssertFalse(app.buttons["project.quoteStyle"].exists)
            capture(free ? "quote-settings-free-clean" : "quote-settings-pro-clean")
            app.navigationBars.buttons["Done"].tap()
            if !free {
                app.tabBars.buttons["Settings"].tap()
                let company = app.buttons["Company profile"]
                reveal(company, in: app); company.tap()
                let logo = app.buttons["Choose company logo"]
                reveal(logo, in: app)
                XCTAssertFalse(app.textFields["Default terms for new projects"].exists)
                capture("company-profile-without-terms")
                app.navigationBars.buttons["Save"].tap()
            }
            app.terminate()
        }
    }

    func testStyleGalleryAtLargestTextSize() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--workflow-free", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en", "--marketing-screen", "quote", "--marketing-locale", "en-US", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let choose = app.buttons["quote.style.choose"]
        XCTAssertTrue(choose.waitForExistence(timeout: 5)); choose.tap()
        let blue = app.buttons["quote.style.blue"]
        reveal(blue, in: app)
        capture("styles-gallery-accessibility")
        blue.tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 3)); XCTAssertTrue(choose.label.contains("Clear Blue"))
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
    }
    func testDefaultQuoteSettingsApplyToBothCreationFlows() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en"]
        app.launch(); defer { app.terminate() }
        app.tabBars.buttons["Settings"].tap()
        let defaults = app.buttons["settings.quoteStyle"]
        reveal(defaults, in: app); defaults.tap()
        let forest = app.buttons["quote.style.forest"]
        reveal(forest, in: app); forest.tap()
        let paper = app.buttons["settings.paper"]
        reveal(paper, in: app); paper.tap(); app.buttons["US Letter"].tap()
        let back = app.buttons["BackButton"].firstMatch
        if back.waitForExistence(timeout: 2) { back.tap() }
        XCTAssertTrue(defaults.waitForExistence(timeout: 5))
        reveal(defaults, in: app)
        XCTAssertTrue(defaults.label.contains("Forest"))
        XCTAssertTrue(paper.label.contains("US Letter") || (paper.value as? String)?.contains("US Letter") == true)
        capture("quote-defaults-settings-light")

        app.tabBars.buttons["Projects"].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        func checkProject(paper expectedPaper: String) {
            app.buttons["project.menu"].tap(); app.buttons["Project settings"].tap()
            XCTAssertFalse(app.buttons["project.quoteStyle"].exists)
            let projectPaper = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Paper size")).firstMatch
            reveal(projectPaper, in: app)
            XCTAssertTrue(projectPaper.label.contains(expectedPaper) || (projectPaper.value as? String)?.contains(expectedPaper) == true, projectPaper.debugDescription)
            app.navigationBars.buttons["Cancel"].tap()
        }
        checkProject(paper: "A4")
        // Existing projects must also use the current global default for new previews.
        let previewStyle = app.buttons["quote.style.choose"]
        app.buttons["Quote preview"].tap()
        XCTAssertTrue(previewStyle.waitForExistence(timeout: 5))
        XCTAssertTrue(previewStyle.label.contains("Forest"))
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        app.navigationBars.buttons["Done"].tap()
        checkProject(paper: "A4")
        app.tabBars.buttons["Settings"].tap()
        reveal(defaults, in: app); defaults.tap(); app.buttons["quote.style.blue"].tap()
        app.tabBars.buttons["Projects"].tap()
        app.buttons["Quote preview"].tap()
        XCTAssertTrue(previewStyle.waitForExistence(timeout: 5))
        XCTAssertTrue(previewStyle.label.contains("Clear Blue"), "Changing settings must affect the next preview of an existing project")
        capture("quote-preview-uses-settings-default")
        app.navigationBars.buttons["Done"].tap()
        app.tabBars.buttons["Settings"].tap()
        reveal(defaults, in: app); defaults.tap(); reveal(forest, in: app); forest.tap()
        app.tabBars.buttons["Projects"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["projects.menu"].tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "New project", "projects.menu")).firstMatch.tap()
        app.textFields["Project name"].tap(); app.textFields["Project name"].typeText("Default Style Project")
        app.navigationBars.buttons["Create"].tap()
        app.staticTexts["Default Style Project"].firstMatch.tap()
        checkProject(paper: "US Letter")

        app.tabBars.buttons["Calculate"].tap()
        app.descendants(matching: .any)["profile.plate"].tap()
        let save = app.buttons["calculator.save"]
        reveal(save, in: app); save.tap()
        let name = app.textFields["Project name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Calculator Defaults")
        app.buttons["Done"].tap()
        let createAndAdd = app.buttons["Create and add"]
        reveal(createAndAdd, in: app); createAndAdd.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        app.tabBars.buttons["Projects"].tap()
        // Projects remembers the last opened detail.
        if app.buttons["project.menu"].exists { app.navigationBars.buttons.firstMatch.tap() }
        app.staticTexts["Calculator Defaults"].firstMatch.tap()
        checkProject(paper: "US Letter")

        app.terminate()
        app.launchArguments += ["--ui-dark"]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        reveal(defaults, in: app)
        XCTAssertTrue(defaults.label.contains("Forest"), "Default style survives relaunch")
        XCTAssertTrue(paper.label.contains("US Letter") || (paper.value as? String)?.contains("US Letter") == true)
        capture("quote-defaults-settings-dark")
        // Leave test defaults at the application's original values.
        defaults.tap(); app.buttons["quote.style.classic"].tap()
        reveal(paper, in: app); paper.tap(); app.buttons["A4"].tap()
    }
    func testBusinessStylesCanBeChosenAsDefaultAndUsedInPreview() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en"]
        app.launch(); defer { app.terminate() }
        let defaults = app.buttons["settings.quoteStyle"]
        for (raw, name) in [("executive", "Executive"), ("modern", "Modern Focus"), ("ledger", "Business Ledger")] {
            app.tabBars.buttons["Settings"].tap()
            reveal(defaults, in: app); defaults.tap()
            let card = app.buttons["quote.style." + raw]
            reveal(card, in: app); capture("business-gallery-" + raw); card.tap()
            XCTAssertTrue(defaults.waitForExistence(timeout: 3))
            XCTAssertTrue(defaults.label.contains(name))
            app.tabBars.buttons["Projects"].tap()
            if !app.buttons["project.menu"].exists { app.staticTexts["Workflow Quote"].firstMatch.tap() }
            app.buttons["Quote preview"].tap()
            let chosen = app.buttons["quote.style.choose"]
            XCTAssertTrue(chosen.waitForExistence(timeout: 5))
            XCTAssertTrue(chosen.label.contains(name))
            XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
            capture("business-preview-" + raw)
            app.navigationBars.buttons["Done"].tap()
        }
        app.terminate(); app.launch()
        app.tabBars.buttons["Settings"].tap(); reveal(defaults, in: app)
        XCTAssertTrue(defaults.label.contains("Business Ledger"))
        defaults.tap(); app.buttons["quote.style.classic"].tap()
    }

    func testGermanStyleGalleryInDarkMode() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--workflow-free", "--reset-workflow", "--ui-dark", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE", "-app.language", "de"]
        app.launch(); defer { app.terminate() }
        app.tabBars.buttons["Projekte"].tap()
        app.staticTexts["Workflow Quote"].firstMatch.tap()
        app.buttons["Angebotsvorschau"].tap()
        let choose = app.buttons["quote.style.choose"]
        XCTAssertTrue(choose.waitForExistence(timeout: 5)); choose.tap()
        XCTAssertTrue(app.buttons["quote.style.blue"].waitForExistence(timeout: 5))
        capture("styles-gallery-dark-de")
        let forest = app.buttons["quote.style.forest"]
        reveal(forest, in: app); capture("styles-gallery-dark-de-lower"); forest.tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 3)); XCTAssertTrue(choose.label.contains("Waldgrün"))
        XCTAssertTrue(app.buttons["quote.save_share"].isEnabled)
        capture("styles-preview-dark-de")
    }
}
