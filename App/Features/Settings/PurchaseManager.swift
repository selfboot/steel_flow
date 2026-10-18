import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()
    static let productID = "com.steelflow.app.pro.lifetime"
    static let entitlementIDFallback = "pro"

    private(set) var localizedPrice: String?
    private(set) var isPro = UserDefaults.standard.bool(forKey: "purchase.pro.cached")
    private(set) var isLoadingProducts = false
    private(set) var isProcessingTransaction = false
    var isLoading: Bool { isLoadingProducts || isProcessingTransaction }
    private(set) var availabilityMessage: String?
    var alertTitle = ""
    var alertMessage: String?

    private var package: Package?
    private var updatesTask: Task<Void, Never>?

    private var usesWorkflowFixture: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("--workflow-tests")
#else
        false
#endif
    }

    init(startListening: Bool = true) {
        if usesWorkflowFixture { isPro = !ProcessInfo.processInfo.arguments.contains("--workflow-free"); return }
        guard startListening else { return }
        guard configureRevenueCatIfNeeded() else {
            availabilityMessage = AppLocalization.text("purchase.configuration_missing")
            return
        }
        updatesTask = Task { [weak self] in
            await self?.observeCustomerInfoUpdates()
        }
    }

    var isPurchaseAvailable: Bool { package != nil && Purchases.isConfigured }

    func trackPaywallImpression(reason: ProPaywallReason) {
        guard !usesWorkflowFixture, !isPro, configureRevenueCatIfNeeded() else { return }
        Purchases.shared.trackCustomPaywallImpression(
            .init(paywallId: "steelflow.\(reason.rawValue)")
        )
    }

    func load() async {
        if usesWorkflowFixture { return }
        guard configureRevenueCatIfNeeded() else {
            availabilityMessage = AppLocalization.text("purchase.configuration_missing")
            return
        }
        await loadProduct {
            let offerings = try await Purchases.shared.offerings()
            return offerings.current?.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.productID
            }
        }
        // Entitlements are refreshed by the app lifecycle and customerInfoStream.
        // Their network state must never prevent a loaded product from being purchased.
    }

    func loadProduct(fetchPackage: () async throws -> Package?) async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        availabilityMessage = nil
        defer { isLoadingProducts = false }
        do {
            let loadedPackage = try await fetchPackage()
            try Task.checkCancellation()
            package = loadedPackage
            localizedPrice = package?.storeProduct.localizedPriceString
            if package == nil {
                availabilityMessage = AppLocalization.text("purchase.product_missing")
            }
        } catch is CancellationError {
            // Closing a sheet is not a store error. Preserve any previously loaded product.
        } catch {
            guard !Task.isCancelled else { return }
            if package == nil { availabilityMessage = error.localizedDescription }
        }
    }

    func purchase() async {
        guard !isProcessingTransaction else { return }
        guard configureRevenueCatIfNeeded(), let package else {
            showAlert(titleKey: "purchase.error", messageKey: "purchase.product_missing")
            return
        }
        isProcessingTransaction = true
        defer { isProcessingTransaction = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return }
            apply(result.customerInfo)
            if !isPro {
                showAlert(titleKey: "purchase.pending.title", messageKey: "purchase.pending.message")
            }
        } catch ErrorCode.paymentPendingError {
            showAlert(titleKey: "purchase.pending.title", messageKey: "purchase.pending.message")
        } catch {
            showAlert(titleKey: "purchase.error", message: error.localizedDescription)
        }
    }

    func restore() async {
        guard !isProcessingTransaction else { return }
        guard configureRevenueCatIfNeeded() else {
            showAlert(titleKey: "purchase.error", messageKey: "purchase.configuration_missing")
            return
        }
        isProcessingTransaction = true
        defer { isProcessingTransaction = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
            if isPro {
                showAlert(titleKey: "purchase.restore.success.title", messageKey: "purchase.restore.success.message")
            } else {
                showAlert(titleKey: "purchase.restore.empty.title", messageKey: "purchase.restore.empty.message")
            }
        } catch {
            showAlert(titleKey: "purchase.error", message: error.localizedDescription)
        }
    }

    func refreshEntitlement() async {
        if usesWorkflowFixture { return }
        guard configureRevenueCatIfNeeded() else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            // RevenueCat caches CustomerInfo. If even that is unavailable, preserve the last
            // server-verified value instead of locking a paid user out while offline.
        }
    }

    static func resolvedEntitlement(hasVerifiedCurrentEntitlement: Bool) -> Bool {
        hasVerifiedCurrentEntitlement
    }

    static func isAcceptableAPIKey(_ rawKey: String, debugBuild: Bool) -> Bool {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedPrefix: String
        if key.hasPrefix("appl_") {
            allowedPrefix = "appl_"
        } else if debugBuild, key.hasPrefix("test_") {
            allowedPrefix = "test_"
        } else {
            return false
        }
        let suffix = key.dropFirst(allowedPrefix.count)
        return suffix.count >= 16 && suffix.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

    private func observeCustomerInfoUpdates() async {
        for await customerInfo in Purchases.shared.customerInfoStream {
            guard !Task.isCancelled else { return }
            apply(customerInfo)
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        isPro = Self.resolvedEntitlement(
            hasVerifiedCurrentEntitlement: customerInfo.entitlements[entitlementID]?.isActive == true
        )
        persistEntitlement()
    }

    private var entitlementID: String {
        let configured = Bundle.main.object(forInfoDictionaryKey: "RevenueCatEntitlementID") as? String
        let value = configured?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty || value.contains("$(") ? Self.entitlementIDFallback : value
    }

    private func configureRevenueCatIfNeeded() -> Bool {
        if Purchases.isConfigured { return true }
        let rawKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? ""
#if DEBUG
        let debugBuild = true
#else
        let debugBuild = false
#endif
        guard Self.isAcceptableAPIKey(rawKey, debugBuild: debugBuild) else { return false }

        if let rawProxyURL = Bundle.main.object(forInfoDictionaryKey: "RevenueCatProxyURL") as? String,
           let proxyURL = URL(string: rawProxyURL), proxyURL.scheme == "https" {
            Purchases.proxyURL = proxyURL
        }
#if DEBUG
        Purchases.logLevel = .debug
#endif
        Purchases.configure(withAPIKey: rawKey.trimmingCharacters(in: .whitespacesAndNewlines))
        return true
    }

    private func persistEntitlement() {
        UserDefaults.standard.set(isPro, forKey: "purchase.pro.cached")
    }

    private func showAlert(titleKey: String, messageKey: String) {
        showAlert(titleKey: titleKey, message: AppLocalization.text(messageKey))
    }

    private func showAlert(titleKey: String, message: String) {
        alertTitle = AppLocalization.text(titleKey)
        alertMessage = message
    }
}

enum ProPolicy {
    static let freeActiveProjectLimit = 2
    static let freeItemsPerProjectLimit = 10

    static func canActivateProject(activeProjectCount: Int, isPro: Bool) -> Bool {
        isPro || activeProjectCount < freeActiveProjectLimit
    }
}
