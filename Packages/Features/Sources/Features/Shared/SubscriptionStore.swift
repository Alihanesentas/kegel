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
    /// Set once by ``setSubscriptionBuild()``. When `true`, ``refresh()``
    /// stops asking `provider` for entitlement state — nothing (a network
    /// hiccup, a lapsed sandbox receipt, RevenueCat itself) can ever flip
    /// ``isSubscribed`` back to `false` for the rest of the process.
    private var isForcedSubscribed = false

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
        guard !isForcedSubscribed else { return }
        isSubscribed = await provider.isSubscribed
    }

    /// Permanently forces this store into a subscribed state, bypassing
    /// `provider` entirely. Called once from ``AppModel/init`` when
    /// ``SubscriptionBuildConfiguration/isSubscriptionBuild`` is `true`.
    /// Never called in a normal build.
    public func setSubscriptionBuild() {
        isForcedSubscribed = true
        isSubscribed = true
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
