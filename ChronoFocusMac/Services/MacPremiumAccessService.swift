import Combine
import Foundation
import StoreKit

@MainActor
final class MacPremiumAccessService: ObservableObject {
    static let proProductID = "com.example.ChronoFocus.pro.analytics"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isProUnlocked = false
    @Published private(set) var statusText = "Pro 统计可通过内购解锁。"
    @Published private(set) var isLoading = false

    private var transactionUpdates: Task<Void, Never>?

    init(loadProductsOnInit: Bool = true, isProUnlockedForSnapshots: Bool = false) {
        isProUnlocked = isProUnlockedForSnapshots
        if isProUnlockedForSnapshots {
            statusText = "Pro 统计已解锁。"
        }
        transactionUpdates = listenForTransactionUpdates()
        if loadProductsOnInit {
            Task {
                await refreshEntitlements()
                await loadProducts()
            }
        }
    }

    deinit {
        transactionUpdates?.cancel()
    }

    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    var priceText: String {
        proProduct?.displayPrice ?? "内购解锁"
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [Self.proProductID])
            if products.isEmpty {
                statusText = "未找到 Pro 商品。请确认 App Store Connect 或 StoreKit 配置。"
            }
        } catch {
            statusText = "暂时无法载入 Pro 商品。"
        }
    }

    func purchasePro() async {
        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            statusText = "Pro 商品尚不可用。"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                guard let transaction = verifiedTransaction(from: verification) else {
                    statusText = "购买验证失败。"
                    return
                }
                isProUnlocked = true
                statusText = "Pro 统计已解锁。"
                await transaction.finish()
            case .userCancelled:
                statusText = "购买已取消。"
            case .pending:
                statusText = "购买待确认。"
            @unknown default:
                statusText = "购买状态未知。"
            }
        } catch {
            statusText = "购买暂时失败，请稍后重试。"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusText = isProUnlocked ? "Pro 统计已恢复。" : "没有找到可恢复的 Pro 权益。"
        } catch {
            statusText = "恢复购买失败。"
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = verifiedTransaction(from: entitlement) else { continue }
            if transaction.productID == Self.proProductID && transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }

        isProUnlocked = unlocked
        if unlocked {
            statusText = "Pro 统计已解锁。"
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if let transaction = self.verifiedTransaction(from: update) {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func verifiedTransaction(
        from verification: VerificationResult<Transaction>
    ) -> Transaction? {
        switch verification {
        case let .verified(transaction):
            return transaction
        case .unverified:
            return nil
        }
    }
}
