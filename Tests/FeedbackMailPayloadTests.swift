import XCTest
@testable import SteelFlow

@MainActor
final class FeedbackMailPayloadTests: XCTestCase {
    func testPayloadIncludesCategorySummaryDetailsAndDiagnostics() throws {
        let payload = FeedbackMailPayload.make(
            category: .feature,
            summary: "  Add templates  ",
            details: "  Please support reusable quote templates.  ",
            diagnostics: FeedbackDiagnostics(
                appVersion: "1.0 (4)",
                device: "iPhone",
                systemVersion: "iOS 26.0",
                locale: "en_US"
            )
        )

        XCTAssertEqual(payload.subject, "[Feature] Add templates")
        XCTAssertTrue(payload.body.contains("Please support reusable quote templates."))
        XCTAssertTrue(payload.body.contains("App version: 1.0 (4)"))
        XCTAssertTrue(payload.body.contains("System: iOS 26.0"))
        XCTAssertEqual(payload.mailtoURL?.scheme, "mailto")
        XCTAssertTrue(payload.clipboardText.contains(FeedbackMailPayload.recipient))
    }
}
