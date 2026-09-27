import Foundation
import StoreKit
import SwiftUI

/// Records requests, not ratings: StoreKit doesn't report whether a review was shown or submitted.
@MainActor
final class AppReviewPrompt {
    static let reviewURL = URL(string: "https://apps.apple.com/app/id6806282417?action=write-review")!
    static let minimumInterval: TimeInterval = 90 * 24 * 60 * 60
    static let shared: AppReviewPrompt = {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--review-prompt-tests") {
            let suite = "com.steelflow.review-prompt-tests"
            let defaults = UserDefaults(suiteName: suite)!
            if ProcessInfo.processInfo.arguments.contains("--reset-review-prompt") {
                defaults.removePersistentDomain(forName: suite)
            }
            return AppReviewPrompt(defaults: defaults)
        }
#endif
        return AppReviewPrompt(defaults: .standard)
    }()

    private let defaults: UserDefaults
    private let versionKey = "review.lastRequestedVersion"
    private let dateKey = "review.lastRequestedAt"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func claimRequest(version: String, now: Date = .now) -> Bool {
        guard !version.isEmpty, defaults.string(forKey: versionKey) != version else { return false }
        if let previousDate = defaults.object(forKey: dateKey) as? Date,
           now.timeIntervalSince(previousDate) < Self.minimumInterval { return false }
        defaults.set(version, forKey: versionKey)
        defaults.set(now, forKey: dateKey)
        return true
    }
}

struct CalculationReviewModifier: ViewModifier {
    let state: DraftState
    let isReady: Bool
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    private struct Trigger: Equatable {
        let state: DraftState
        let isReady: Bool
    }

    func body(content: Content) -> some View {
        content.task(id: Trigger(state: state, isReady: isReady && scenePhase == .active)) {
            guard isReady, scenePhase == .active else { return }
#if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            guard !arguments.contains("--marketing-screen") else { return }
            if !arguments.contains("--review-prompt-tests"),
               arguments.contains("--workflow-tests") || arguments.contains("--reset-workflow") { return }
#endif
            // Any further edit, open sheet, backgrounding or navigation cancels this task.
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            guard !Task.isCancelled else { return }
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            if AppReviewPrompt.shared.claimRequest(version: version) {
                requestReview()
            }
        }
    }
}
