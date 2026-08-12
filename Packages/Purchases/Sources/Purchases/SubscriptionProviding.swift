/// Subscription state and purchasing, behind a protocol so the app never sees
/// RevenueCat's types directly — see CLAUDE.md sections 2 and 3.
public protocol SubscriptionProviding: Sendable {
    var isSubscribed: Bool { get async }

    /// Ties purchases to the app's anonymous ID so a reinstall can restore
    /// without an account (CLAUDE.md section 5 — no sign-in, ever).
    func configure(anonymousID: String) async

    /// Plans to show on the paywall. Empty when the store is unreachable or
    /// nothing is configured yet; the paywall handles that case.
    func availablePlans() async -> [SubscriptionPlan]

    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
}

/// Used in previews, tests, and any build where purchasing is deliberately off.
/// Reports "not subscribed" and offers nothing to buy.
public struct NoOpSubscriptionProvider: SubscriptionProviding {
    public init() {}

    public var isSubscribed: Bool {
        get async { false }
    }

    public func configure(anonymousID _: String) async {}
    public func availablePlans() async -> [SubscriptionPlan] {
        []
    }

    public func purchase(_: SubscriptionPlan) async throws {}
    public func restorePurchases() async throws {}
}
