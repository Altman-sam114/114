import Combine
import Foundation
import StoreKit

@MainActor
final class MacPremiumAccessService: ObservableObject {
    static let proProductID = "com.example.ChronoFocus.pro.analytics"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isProUnlocked = false
    @Published private(set) var statusText = "Pro 统计可通过内购解锁。"
    @Published private(set) var activityText: String?

    var isLoading: Bool { activityText != nil }

    private let productLoader: @MainActor () async throws -> [Product]
    private var transactionUpdates: Task<Void, Never>?

    init(loadProductsOnInit: Bool = true, isProUnlockedForSnapshots: Bool = false,
         productLoader: (@MainActor () async throws -> [Product])? = nil) {
        let productID = Self.proProductID
        self.productLoader = productLoader ?? { try await Product.products(for: [productID]) }
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
        guard !isLoading else { return }
        activityText = "正在连接 App Store…"
        defer { activityText = nil }
        await fetchProducts()
    }

    private func fetchProducts() async {
        do {
            products = try await productLoader()
            if products.isEmpty {
                statusText = "暂时无法提供 Pro 购买，请稍后重试。"
            }
        } catch {
            statusText = "暂时无法载入 Pro 商品。"
        }
    }

    func purchasePro() async {
        guard !isLoading, !isProUnlocked else { return }
        activityText = "正在准备购买…"
        defer { activityText = nil }

        if proProduct == nil {
            await fetchProducts()
        }

        guard let product = proProduct else {
            statusText = "Pro 商品尚不可用。"
            return
        }

        activityText = "正在等待购买结果…"
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
        guard !isLoading else { return }
        activityText = "正在恢复购买…"
        defer { activityText = nil }

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

        let wasUnlocked = isProUnlocked
        isProUnlocked = unlocked
        if unlocked {
            statusText = "Pro 统计已解锁。"
        } else if wasUnlocked {
            statusText = "Pro 权益已失效，可重新购买或恢复。"
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
