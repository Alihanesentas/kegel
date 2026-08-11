import Foundation
import Observation
import Purchases

/// Observable view of subscription state.
///
/// Sits on top of `SubscriptionProviding`, so no screen ever imports
/// RevenueCat (CLAUDE.md section 3 — third-party SDKs stay inside one package).
@MainActor
@Observable
public final class SubscriptionStore {
    public private(set) var isSubscribed = false
    public private(set) var plans: [SubscriptionPlan] = []
    public private(set) var isWorking = false
    /// Set when a purchase or restore genuinely failed. A user-cancelled
    /// purchase is not an error and never lands here.
    public private(set) var lastError: SubscriptionError?

    private let provider: any SubscriptionProviding

    public init(provider: any SubscriptionProviding) {
        self.provider = provider
    }

    /// Hands the app's anonymous ID to the store so purchases survive a
    /// reinstall without any account.
    public func configure(anonymousID: String) async {
        await provider.configure(anonymousID: anonymousID)
        await refresh()
    }

    public func refresh() async {
        isSubscribed = await provider.isSubscribed
    }

    public func loadPlans() async {
        plans = await provider.availablePlans()
    }

    public func purchase(_ plan: SubscriptionPlan) async {
        isWorking = true
        lastError = nil
        defer { isWorking = false }

        do {
            try await provider.purchase(plan)
            await refresh()
        } catch SubscriptionError.cancelled {
            // Backing out of the store sheet is a normal thing to do.
        } catch let error as SubscriptionError {
            lastError = error
        } catch {
            lastError = .failed(error.localizedDescription)
        }
    }

    public func restore() async {
        isWorking = true
        lastError = nil
        defer { isWorking = false }

        do {
            try await provider.restorePurchases()
            await refresh()
        } catch let error as SubscriptionError {
            lastError = error
        } catch {
            lastError = .failed(error.localizedDescription)
        }
    }

    public func clearError() {
        lastError = nil
    }
}
