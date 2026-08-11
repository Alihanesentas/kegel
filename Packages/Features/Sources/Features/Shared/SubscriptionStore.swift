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
    public private(set) var isWorking = false

    private let provider: any SubscriptionProviding

    public init(provider: any SubscriptionProviding) {
        self.provider = provider
    }

    public func refresh() async {
        isSubscribed = await provider.isSubscribed
    }

    public func purchase(productID: String) async {
        isWorking = true
        defer { isWorking = false }
        try? await provider.purchase(productID: productID)
        await refresh()
    }

    public func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await provider.restorePurchases()
        await refresh()
    }
}
