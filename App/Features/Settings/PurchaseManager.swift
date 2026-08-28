import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()
    static let productID = "com.steelflow.app.pro.lifetime"
    var product: Product?
    var isPro = UserDefaults.standard.bool(forKey: "purchase.pro.cached")
    var isLoading = false
    var errorMessage: String?
    private var updatesTask: Task<Void, Never>?

    init(startListening: Bool = true) {
        guard startListening else { return }
        updatesTask = Task { [weak self] in
            await self?.refreshEntitlement()
            await self?.observeTransactionUpdates()
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch { errorMessage = error.localizedDescription }
        await refreshEntitlement()
    }

    func purchase() async {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result {
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlement()
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verified(result), transaction.productID == Self.productID, transaction.revocationDate == nil {
                entitled = true
            }
        }
        isPro = Self.resolvedEntitlement(hasVerifiedCurrentEntitlement: entitled)
        UserDefaults.standard.set(isPro, forKey: "purchase.pro.cached")
    }

    static func resolvedEntitlement(hasVerifiedCurrentEntitlement: Bool) -> Bool {
        hasVerifiedCurrentEntitlement
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }
            if let transaction = try? verified(result), transaction.productID == Self.productID {
                await transaction.finish()
            }
            await refreshEntitlement()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw StoreKitError.notEntitled
        }
    }
}

enum ProPolicy {
    static let freeActiveProjectLimit = 2
    static let freeItemsPerProjectLimit = 10
}
