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

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            product = try await Product.products(for: [Self.productID]).first
            await refreshEntitlement()
        } catch { errorMessage = error.localizedDescription }
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
        isPro = entitled || isPro
        UserDefaults.standard.set(isPro, forKey: "purchase.pro.cached")
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
