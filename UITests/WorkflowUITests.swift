import XCTest

@MainActor final class WorkflowUITests: XCTestCase {
    private func launch(chinese: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--workflow-tests", "--reset-workflow", "-AppleLanguages", chinese ? "(zh-Hans)" : "(en)", "-AppleLocale", chinese ? "zh_CN" : "en_US", "-app.language", chinese ? "zh-Hans" : "en", "-app.currency", "USD", "-app.unitSystem", "metric"]
        app.launch()
        return app
    }
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 5)); XCTAssertTrue(element.isHittable); element.tap()
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
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
        XCTAssertTrue(app.navigationBars["Change project currency"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "USD")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "CNY")).firstMatch.exists)
        capture(app, "cross-currency-save")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Save to project"].waitForExistence(timeout: 5))
    }
    func testFavoriteCalculationCanBeReopenedWithoutSavingProject() {
        let app = launch()
        app.descendants(matching: .any)["profile.plate"].tap()
        app.buttons["calculator.menu"].tap()
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
        tap(app.buttons["Save this quote version"], in: app)
        XCTAssertTrue(app.buttons["Version saved"].waitForExistence(timeout: 4))
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
        let waste = app.textFields["Waste"]
        tap(waste, in: app)
        waste.typeText(XCUIKeyboardKey.delete.rawValue + "10")
        app.buttons["Done"].tap()
        tap(app.buttons["Select visible items"], in: app)
        tap(app.switches["Aluminum tube"], in: app)
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
        capture(app, "template-picker")
    }
    func testChineseQuickCalculationAndPriceDetails() {
        let app = launch(chinese: true)
        app.descendants(matching: .any)["profile.plate"].tap()
        XCTAssertTrue(app.staticTexts["47.1 kg"].firstMatch.waitForExistence(timeout: 4))
        let toggle = app.switches["workflow.pricing_toggle"]
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
        let price = app.textFields["calculator.price_input"]
        for _ in 0..<12 where !price.isHittable { app.swipeUp() }
        capture(app, "chinese-pricing")
        XCTAssertTrue(price.exists)
    }
}
