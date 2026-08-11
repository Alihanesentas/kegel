/// Subscription state, behind a protocol so the app never sees RevenueCat's
/// `Purchases` type directly — see CLAUDE.md section 2 for why RevenueCat was chosen.
public protocol SubscriptionProviding: Sendable {
    var isSubscribed: Bool { get async }
    func purchase(productID: String) async throws
    func restorePurchases() async throws
}

/// Placeholder until the RevenueCat-backed implementation lands — that's M3
/// work (CLAUDE.md roadmap), not part of this milestone. Always reports
/// "not subscribed"; purchase/restore are no-ops.
public struct NoOpSubscriptionProvider: SubscriptionProviding {
    public init() {}

    public var isSubscribed: Bool {
        get async { false }
    }

    public func purchase(productID: String) async throws {}
    public func restorePurchases() async throws {}
}
