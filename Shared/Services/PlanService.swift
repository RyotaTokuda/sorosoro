import Foundation
import StoreKit

@Observable
final class PlanService {
    private(set) var isPro: Bool = false
    private(set) var products: [Product] = []
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await updatePurchaseStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: AppConstants.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("[PlanService] loadProducts error: \(error)")
        }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.plusMonthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.plusYearlyID }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchaseStatus()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    // MARK: - Status

    func updatePurchaseStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if AppConstants.allProductIDs.contains(transaction.productID) {
                    hasActive = true
                    break
                }
            }
        }
        isPro = hasActive
    }

    // MARK: - Limits

    func itemLimit() -> Int {
        PlanLimits.itemLimit(isPro: isPro)
    }

    func canAddItem(currentCount: Int) -> Bool {
        currentCount < itemLimit()
    }

    func notificationLimit() -> Int {
        PlanLimits.notificationLimit(isPro: isPro)
    }

    func canCreateCustomTemplate() -> Bool {
        PlanLimits.canCreateCustomTemplate(isPro: isPro)
    }

    func canUseAllModes() -> Bool {
        PlanLimits.canUseAllModes(isPro: isPro)
    }

    func canCrossModeShopping() -> Bool {
        PlanLimits.canCrossModeShopping(isPro: isPro)
    }

    func canUseMemo() -> Bool {
        PlanLimits.canUseMemo(isPro: isPro)
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.updatePurchaseStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }

}
