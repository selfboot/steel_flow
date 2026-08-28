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
    private(set) var isLoading = false
    private(set) var availabilityMessage: String?
    var alertTitle = ""
    var alertMessage: String?

    private var package: Package?
    private var updatesTask: Task<Void, Never>?

    init(startListening: Bool = true) {
        guard startListening else { return }
        guard configureRevenueCatIfNeeded() else {
            isPro = false
            persistEntitlement()
            availabilityMessage = String(localized: "purchase.configuration_missing")
            return
        }
        updatesTask = Task { [weak self] in
            await self?.refreshEntitlement()
            await self?.observeCustomerInfoUpdates()
        }
    }

    var isPurchaseAvailable: Bool { package != nil && Purchases.isConfigured }

    func load() async {
        guard configureRevenueCatIfNeeded() else {
            availabilityMessage = String(localized: "purchase.configuration_missing")
            return
        }
        isLoading = true
        availabilityMessage = nil
        defer { isLoading = false }
        do {
            async let offerings = Purchases.shared.offerings()
            async let customerInfo = Purchases.shared.customerInfo()
            let (loadedOfferings, loadedCustomerInfo) = try await (offerings, customerInfo)
            package = loadedOfferings.current?.availablePackages.first {
                $0.storeProduct.productIdentifier == Self.productID
            }
            localizedPrice = package?.storeProduct.localizedPriceString
            if package == nil {
                availabilityMessage = String(localized: "purchase.product_missing")
            }
            apply(loadedCustomerInfo)
        } catch {
            // Keep the last verified entitlement when the service is temporarily unreachable.
            availabilityMessage = error.localizedDescription
        }
    }

    func purchase() async {
        guard configureRevenueCatIfNeeded(), let package else {
            showAlert(titleKey: "purchase.error", messageKey: "purchase.product_missing")
            return
        }
        isLoading = true
        defer { isLoading = false }
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
        guard configureRevenueCatIfNeeded() else {
            showAlert(titleKey: "purchase.error", messageKey: "purchase.configuration_missing")
            return
        }
        isLoading = true
        defer { isLoading = false }
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
        if key.hasPrefix("appl_") { return true }
        return debugBuild && key.hasPrefix("test_")
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
        showAlert(titleKey: titleKey, message: String(localized: String.LocalizationValue(messageKey)))
    }

    private func showAlert(titleKey: String, message: String) {
        alertTitle = String(localized: String.LocalizationValue(titleKey))
        alertMessage = message
    }
}

enum ProPolicy {
    static let freeActiveProjectLimit = 2
    static let freeItemsPerProjectLimit = 10
}
