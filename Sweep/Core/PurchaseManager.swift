import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    static let proLifetimeID = "by.timberbid.sweep.pro.lifetime"

    private(set) var proProduct: Product?
    private(set) var isPro: Bool = false
    private(set) var isLoading: Bool = false
    var lastError: String?

    private let taskHolder = TaskHolder()

    init() {
        Task { await refreshEntitlements() }
        Task { await loadProduct() }
        taskHolder.task = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    private final class TaskHolder: @unchecked Sendable {
        var task: Task<Void, Never>?
        deinit { task?.cancel() }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.proLifetimeID])
            proProduct = products.first
        } catch {
            lastError = "Couldn't load product: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case let .verified(t) = result, t.productID == Self.proLifetimeID, t.revocationDate == nil {
                isPro = true
                return
            }
        }
        isPro = false
    }

    /// Returns true if a transaction was completed (verified) — caller can dismiss the paywall.
    func buy() async -> Bool {
        guard let proProduct else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                if case let .verified(t) = verification {
                    await t.finish()
                    isPro = true
                    return true
                } else {
                    lastError = "Purchase couldn't be verified."
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case let .verified(t) = result {
            if t.productID == Self.proLifetimeID && t.revocationDate == nil {
                isPro = true
            }
            await t.finish()
        }
    }
}

/// Free-tier rolling-window quota for deletions. Persists in UserDefaults.
@MainActor
final class FreeQuota {
    static let shared = FreeQuota()
    private let key = "Sweep.freeQuota.events"
    private let windowSeconds: TimeInterval = 7 * 24 * 3600
    /// Maximum deletions allowed in `windowSeconds` for free users.
    let weeklyLimit = 20

    private init() {}

    func usedThisWindow() -> Int {
        prune().count
    }

    func remainingThisWindow() -> Int {
        max(0, weeklyLimit - usedThisWindow())
    }

    func canDelete(_ count: Int) -> Bool {
        usedThisWindow() + count <= weeklyLimit
    }

    func record(_ count: Int) {
        let now = Date().timeIntervalSince1970
        var events = prune()
        events.append(contentsOf: Array(repeating: now, count: count))
        UserDefaults.standard.set(events, forKey: key)
    }

    private func prune() -> [TimeInterval] {
        let stored = UserDefaults.standard.array(forKey: key) as? [TimeInterval] ?? []
        let cutoff = Date().timeIntervalSince1970 - windowSeconds
        let kept = stored.filter { $0 >= cutoff }
        if kept.count != stored.count {
            UserDefaults.standard.set(kept, forKey: key)
        }
        return kept
    }
}
