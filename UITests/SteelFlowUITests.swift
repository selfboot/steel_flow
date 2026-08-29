import XCTest

@MainActor
final class SteelFlowUITests: XCTestCase {
    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en", "-app.unitSystem", "metric"] + extraArguments
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
        let totalMass = app.staticTexts["Total mass"]
        for _ in 0..<8 where !totalMass.isHittable { app.swipeUp() }
        XCTAssertTrue(totalMass.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["47.1 kg"].waitForExistence(timeout: 2))
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
        valueField.tap(withNumberOfTaps: 2, numberOfTouches: 1)
        valueField.typeText("7.25")
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
        quantityField.tap(withNumberOfTaps: 2, numberOfTouches: 1)
        quantityField.typeText("12500")
        XCTAssertEqual(quantityField.value as? String, "12500")
        app.buttons["Done"].tap()
        XCTAssertEqual(quantityField.value as? String, "12500")
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

    func testLockedFeatureOpensPurchaseLandingPageWithStoreProduct() {
        continueAfterFailure = false
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

    func testPurchaseInvokesStoreKitAndCancellationIsHandledCleanly() {
        continueAfterFailure = false
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
        XCTAssertTrue(app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Width'")).firstMatch.waitForExistence(timeout: 3))
        attachScreenshot(named: "accessibility-xxxl-calculator")
    }

    func testChineseQuoteRowsDoNotOverlapOnCompactPhone() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "zh-Hans",
            "-app.unitSystem", "metric", "-app.currency", "CNY",
            "--marketing-screen", "quote", "--marketing-locale", "zh-Hans"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["报价预览"].waitForExistence(timeout: 8))
        let title = app.staticTexts["连接角钢 L75 × 6"]
        let mass = app.staticTexts["1,220.83 kg"]
        let amount = app.staticTexts["¥8,495.98"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertTrue(mass.waitForExistence(timeout: 3))
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        XCTAssertFalse(title.frame.intersects(mass.frame), "The item title must not overlap the mass column")
        XCTAssertFalse(mass.frame.intersects(amount.frame), "Mass and amount must remain separately readable")
        XCTAssertGreaterThanOrEqual(mass.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(amount.frame.maxX, app.windows.firstMatch.frame.maxX)
        attachScreenshot(named: "compact-chinese-quote")
    }

    func testEnglishQuoteRowsKeepAmountsInsideCompactPhone() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "quote", "--marketing-locale", "en-US"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Quote preview"].waitForExistence(timeout: 8))
        let title = app.staticTexts["Connection angle L75 × 6"]
        let amount = app.staticTexts["$1,276.03"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        XCTAssertFalse(title.frame.intersects(amount.frame))
        XCTAssertLessThanOrEqual(amount.frame.maxX, app.windows.firstMatch.frame.maxX)
        attachScreenshot(named: "compact-english-quote")
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
        let label = app.staticTexts["加工及其他费用"]
        let amount = app.staticTexts["¥2,280.00"]
        for _ in 0..<4 where !label.isHittable { app.swipeUp() }
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        XCTAssertFalse(label.frame.intersects(amount.frame))
        XCTAssertLessThanOrEqual(amount.frame.maxX, app.windows.firstMatch.frame.maxX)
        attachScreenshot(named: "compact-chinese-project-summary")
    }

    func testQuoteBodyUsesProjectLanguageAndDoesNotExposeInternalPricing() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "quote", "--marketing-locale", "zh-Hans"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Quote preview"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["报价单"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["税前小计"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Material subtotal"].exists)
        XCTAssertFalse(app.staticTexts["Markup"].exists)
        attachScreenshot(named: "quote-language-and-customer-safe-pricing")
    }

    func testPriceDeletionRequiresExplicitConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-app.language", "en",
            "--marketing-screen", "materials", "--marketing-locale", "en-US"
        ]
        app.launch()

        let price = app.staticTexts["Q235B regional spot"]
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
