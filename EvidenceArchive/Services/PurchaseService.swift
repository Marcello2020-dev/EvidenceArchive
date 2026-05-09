import Foundation
import StoreKit

@MainActor
final class PurchaseService: ObservableObject {
    @Published private(set) var hasFullAccess = false
    @Published private(set) var fullAccessProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var lastError: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = observeTransactionUpdates()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [PurchaseConfiguration.fullAccessProductID])
            fullAccessProduct = products.first
            if products.isEmpty {
                lastError = L10n.text("Purchase product is not configured yet.")
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchaseFullAccess() async {
        lastError = nil
        if fullAccessProduct == nil {
            await loadProducts()
        }

        guard let product = fullAccessProduct else {
            lastError = L10n.text("Purchase product is not available.")
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = L10n.text("Purchase could not be verified.")
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                lastError = L10n.text("Purchase is pending approval.")
            case .userCancelled:
                break
            @unknown default:
                lastError = L10n.text("Purchase could not be completed.")
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        lastError = nil

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !hasFullAccess {
                lastError = L10n.text("No previous purchase was found.")
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            if transaction.productID == PurchaseConfiguration.fullAccessProductID,
               transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }

        hasFullAccess = unlocked
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                await self.handleTransactionUpdate(update)
            }
        }
    }

    private func handleTransactionUpdate(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else {
            return
        }

        if transaction.productID == PurchaseConfiguration.fullAccessProductID {
            await refreshEntitlements()
        }

        await transaction.finish()
    }
}
