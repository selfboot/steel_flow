import XCTest

@MainActor final class WorkflowUITests: XCTestCase {
    private func launch(chinese: Bool = false, extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", chinese ? "(zh-Hans)" : "(en)", "-AppleLocale", chinese ? "zh_CN" : "en_US", "-app.language", chinese ? "zh-Hans" : "en", "-app.currency", "USD", "-app.unitSystem", "metric"] + extra
        app.launch()
        return app
    }
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<16 where !element.isHittable {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.22)))
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5)); XCTAssertTrue(element.isHittable); element.tap()
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func openProject(_ app: XCUIApplication) {
        selectTab("Projects", in: app)
        tap(app.staticTexts["Workflow Quote"].firstMatch, in: app)
        XCTAssertTrue(app.navigationBars["Workflow Quote"].waitForExistence(timeout: 5))
    }
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let phoneTab = app.tabBars.buttons[name]
        if phoneTab.exists { phoneTab.tap() }
        else { app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name)).firstMatch.tap() }
    }
    func testCrossCurrencySaveRequiresExplicitChoice() {
        let app = launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        tap(app.buttons["Save to project"], in: app)
        tap(app.staticTexts["Workflow Quote"].firstMatch, in: app)
        XCTAssertTrue(app.navigationBars["Save in project currency"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "USD")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "CNY")).firstMatch.exists)
        capture(app, "cross-currency-save")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Save to project"].waitForExistence(timeout: 5))
    }
    func testFavoriteCalculationCanBeReopenedWithoutSavingProject() {
        let app = launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        app.buttons["Save specification to favorites"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let favorite = app.staticTexts["Favorite specifications"]
        for _ in 0..<8 where !favorite.isHittable { app.swipeUp() }
        XCTAssertTrue(favorite.waitForExistence(timeout: 4))
        capture(app, "favorite-specifications")
        let plate = app.staticTexts.matching(identifier: "Plate / flat bar").allElementsBoundByIndex.last!
        tap(plate, in: app)
        XCTAssertTrue(app.buttons["calculator.menu"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["47.1 kg"].firstMatch.exists)
    }
    func testQuoteVersionCanBeSavedAndReopened() {
        let app = launch(); openProject(app)
        tap(app.buttons["Quote preview"], in: app)
        XCTAssertTrue(app.buttons["quote.save_share"].waitForExistence(timeout: 10))
        tap(app.buttons["Other export options"], in: app)
        tap(app.buttons["Save this quote version"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["quote.version_saved"].waitForExistence(timeout: 4))
        capture(app, "quote-version-export")
        app.navigationBars.buttons["Done"].tap()
        app.buttons["project.menu"].tap()
        app.buttons["Quote history"].tap()
        XCTAssertTrue(app.navigationBars["Quote history"].waitForExistence(timeout: 4))
        let version = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "v1 ·")).firstMatch
        tap(version, in: app)
        XCTAssertTrue(app.staticTexts["This version keeps its original prices, dates and presentation."].waitForExistence(timeout: 4))
        capture(app, "frozen-quote")
    }
    func testSelectiveBatchPricingAndUndoAreAvailable() {
        let app = launch(); openProject(app)
        app.buttons["project.menu"].tap(); app.buttons["Batch pricing"].tap()
        XCTAssertFalse(app.buttons["Apply selected"].isEnabled)
        tap(app.buttons["Select visible items"], in: app)
        XCTAssertFalse(app.buttons["Apply selected"].isEnabled)
        let wasteToggle = app.switches["Update waste for selected items"]
        wasteToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertEqual(wasteToggle.value as? String, "1")
        let waste = app.textFields["Waste"]
        tap(waste, in: app)
        waste.typeText(XCUIKeyboardKey.delete.rawValue + "10")
        app.buttons["Done"].tap()
        tap(app.buttons["Select visible items"], in: app)
        tap(app.buttons["bulk.item.Aluminum tube"], in: app)
        // The selection and preview must exist before the action is enabled.
        XCTAssertTrue(app.buttons["Apply selected"].isEnabled)
        tap(app.buttons["Apply selected"], in: app)
        app.buttons["Apply"].tap()
        let undo = app.buttons["Undo last change"]
        tap(undo, in: app)
        XCTAssertFalse(undo.exists)
        _ = waste
        capture(app, "project-after-undo")
    }
    func testCustomerAndTemplateFlows() {
        let app = launch(); openProject(app)
        app.buttons["project.menu"].tap(); app.buttons["Save as project template"].tap()
        app.alerts.buttons["Save"].tap()
        selectTab("Settings", in: app)
        tap(app.buttons["Customers"], in: app)
        XCTAssertTrue(app.staticTexts["Saved Customer"].waitForExistence(timeout: 4))
        tap(app.buttons["Add customer"], in: app)
        XCTAssertTrue(app.textFields["Customer"].waitForExistence(timeout: 4))
        capture(app, "customer-editor")
        app.buttons["Cancel"].tap(); app.buttons["Done"].tap()
        selectTab("Projects", in: app)
        if app.buttons["project.menu"].exists { app.navigationBars.buttons.element(boundBy: 0).tap() }
        app.buttons["projects.menu"].tap()
        app.buttons["Create from template"].tap()
        XCTAssertTrue(app.staticTexts["Workflow Quote"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["template.create"].isEnabled)
        app.buttons["template.Workflow Quote"].tap()
        XCTAssertTrue(app.buttons["template.create"].isEnabled)
        XCTAssertTrue(app.staticTexts["template.preview.prices"].waitForExistence(timeout: 5))
        capture(app, "template-picker")
        app.buttons["template.create"].tap()
        XCTAssertTrue(app.navigationBars["Workflow Quote"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Quote preview"].exists)
    }
    func testChineseQuickCalculationAndPriceDetails() {
        let app = launch(chinese: true)
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47.1 kg"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "workflow.pricing_toggle").count, 0)
        let price = app.textFields["calculator.price_input"]
        let disclosure = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@ OR label BEGINSWITH %@", "计价", "计价,", "计价、")).firstMatch
        tap(disclosure, in: app)
        tap(price, in: app)
        price.typeText(XCUIKeyboardKey.delete.rawValue + "12.5")
        app.buttons["完成"].tap()
        capture(app, "chinese-pricing")
        for _ in 0..<8 where !disclosure.isHittable { app.swipeDown() }
        disclosure.tap()
        XCTAssertFalse(price.exists)
        capture(app, "pricing-collapsed")
        disclosure.tap()
        tap(price, in: app)
        XCTAssertEqual(Decimal(string: price.value as? String ?? ""), Decimal(string: "12.5"))
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-workflow" }
        app.launch()
        tap(app.descendants(matching: .any)["home.continue"], in: app)
        XCTAssertFalse(price.exists, "Opening a calculation starts with pricing collapsed")
        tap(disclosure, in: app)
        tap(price, in: app)
        XCTAssertEqual(Decimal(string: price.value as? String ?? ""), Decimal(string: "12.5"))
    }
    func testSearchEmptyStateAndMaterialCatalogScopes() {
        let app = launch(); selectTab("Projects", in: app)
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("no-such-customer-983")
        XCTAssertTrue(app.staticTexts["No matching results"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["No projects yet"].exists)
        app.buttons["Clear filters"].tap()
        XCTAssertTrue(app.staticTexts["Workflow Quote"].waitForExistence(timeout: 3))
        selectTab("Materials", in: app)
        XCTAssertTrue(app.segmentedControls.firstMatch.exists)
        app.segmentedControls.buttons["Saved price history"].tap()
        capture(app, "supplier-prices")
        XCTAssertFalse(app.staticTexts["Built-in materials"].exists)
    }
    func testQuantityErrorAndKeyboardNavigation() {
        let app = launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        let quantity = app.textFields["quantity.value"]
        tap(quantity, in: app)
        quantity.typeText(XCUIKeyboardKey.delete.rawValue + "0")
        XCTAssertFalse(app.buttons["calculator.save"].isEnabled)
        XCTAssertTrue(app.buttons["Next"].exists)
        XCTAssertTrue(app.buttons["Previous"].exists)
        app.buttons["Done"].tap()
        XCTAssertEqual(quantity.value as? String, "0")
        capture(app, "quantity-inline-error")
        quantity.tap(); quantity.typeText(XCUIKeyboardKey.delete.rawValue + "3")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["calculator.save"].isEnabled)
        tap(app.textFields["length.value"], in: app)
        app.buttons["Next"].tap(); app.typeText("2")
        XCTAssertEqual(quantity.value as? String, "32")
    }

    func testLargeTextDarkModeAndAccessibleInputs() throws {
        let app = launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "--ui-dark"])
        let plate = app.descendants(matching: .any)["profile.plate"]
        tap(plate, in: app)
        let width = app.textFields["dimension.width"]
        tap(width, in: app)
        XCTAssertTrue(width.label.contains("Width")); XCTAssertTrue(width.label.contains("mm"))
        XCTAssertTrue(app.buttons["calculator.save"].exists)
        app.buttons["Done"].tap()
        capture(app, "dark-accessibility-xxxl")
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .trait])
    }
    func testLandscapeCalculationAndPDFPreview() {
        let app = launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        expectation(for: NSPredicate { _, _ in app.frame.width > app.frame.height }, evaluatedWith: app)
        waitForExpectations(timeout: 8)
        let plate = app.descendants(matching: .any)["profile.plate"]
        tap(plate, in: app)
        XCTAssertTrue(app.buttons["calculator.save"].waitForExistence(timeout: 4))
        capture(app, "landscape-calculator")
        openProject(app)
        tap(app.buttons["Quote preview"], in: app)
        XCTAssertTrue(app.buttons["quote.save_share"].waitForExistence(timeout: 10))
        capture(app, "landscape-pdf-preview")
    }
    func testExportFailureKeepsRetryOnScreen() {
        let app = launch(extra: ["--ui-export-error"]); openProject(app)
        app.buttons["Quote preview"].tap()
        XCTAssertTrue(app.buttons["quote.retry"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["quote.save_share"].isEnabled)
        app.buttons["quote.retry"].tap()
        let ready = NSPredicate(format: "isEnabled == true")
        expectation(for: ready, evaluatedWith: app.buttons["quote.save_share"])
        waitForExpectations(timeout: 10)
        capture(app, "export-retry")
    }

    func testSavedItemFeedbackCanUndoAndOpenDestination() {
        let app = launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        func saveItem() {
            app.buttons["calculator.save"].tap()
            tap(app.staticTexts["Workflow Quote"].firstMatch, in: app)
            let confirm = app.buttons["Clear amounts & save"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5)); confirm.tap()
            XCTAssertTrue(app.buttons["View project"].waitForExistence(timeout: 5))
        }
        saveItem()
        capture(app, "saved-item-feedback")
        app.buttons["Undo last change"].tap()
        XCTAssertTrue(app.staticTexts["The saved item has been removed."].waitForExistence(timeout: 4))
        saveItem()
        app.buttons["View project"].tap()
        XCTAssertTrue(app.navigationBars["Workflow Quote"].waitForExistence(timeout: 5))
        capture(app, "saved-item-destination")
    }

    func testPrimaryExportSavesVersionBeforeOpeningShareSheet() {
        let app = launch(); openProject(app)
        app.buttons["Quote preview"].tap()
        let share = app.buttons["quote.save_share"]
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: share)
        waitForExpectations(timeout: 10)
        share.tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Copy")).firstMatch.exists)
        capture(app, "pdf-system-share")
        let close = app.buttons.matching(NSPredicate(format: "label IN %@", ["Close", "关闭"])).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5)); close.tap()
        XCTAssertTrue(app.buttons["Share PDF quote"].exists)
        let saved = app.descendants(matching: .any)["quote.version_saved"].firstMatch
        for _ in 0..<8 where !saved.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.22)))
        }
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        capture(app, "pdf-version-after-share")
        app.navigationBars.buttons["Done"].tap()
        app.buttons["project.menu"].tap(); app.buttons["Quote history"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "v1 ·")).firstMatch.waitForExistence(timeout: 5))
    }

}
