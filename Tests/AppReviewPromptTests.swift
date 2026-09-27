import XCTest
@testable import SteelFlow

@MainActor
final class AppReviewPromptTests: XCTestCase {
    func testRequestHistorySurvivesRelaunchAndPreventsRepeatedVersionRequests() {
        let suite = "AppReviewPromptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(AppReviewPrompt(defaults: defaults).claimRequest(version: "1.1.1", now: now))
        let relaunched = AppReviewPrompt(defaults: defaults)
        XCTAssertFalse(relaunched.claimRequest(version: "1.1.1", now: now.addingTimeInterval(365 * 86400)))
    }

    func testNewVersionStillWaitsForCooldownAndDoesNotConsumeAnEarlyAttempt() {
        let suite = "AppReviewPromptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = AppReviewPrompt(defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(prompt.claimRequest(version: "1.1.1", now: now))
        XCTAssertFalse(prompt.claimRequest(version: "1.1.2", now: now.addingTimeInterval(89 * 86400)))
        XCTAssertFalse(prompt.claimRequest(version: "1.1.2", now: now.addingTimeInterval(-86400)))
        XCTAssertTrue(prompt.claimRequest(version: "1.1.2", now: now.addingTimeInterval(90 * 86400)))
        XCTAssertFalse(prompt.claimRequest(version: "1.1.2", now: now.addingTimeInterval(180 * 86400)))
    }

    func testMissingVersionDoesNotConsumeFirstRequest() {
        let suite = "AppReviewPromptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = AppReviewPrompt(defaults: defaults)
        XCTAssertFalse(prompt.claimRequest(version: ""))
        XCTAssertTrue(prompt.claimRequest(version: "1.1.1"))
    }

    func testManualReviewLinkTargetsSteelFlowWriteReviewPage() {
        let components = URLComponents(url: AppReviewPrompt.reviewURL, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.host, "apps.apple.com")
        XCTAssertEqual(components?.path, "/app/id6806282417")
        XCTAssertEqual(components?.queryItems, [URLQueryItem(name: "action", value: "write-review")])
    }
}
