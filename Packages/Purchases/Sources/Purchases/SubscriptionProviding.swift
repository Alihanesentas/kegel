/// Subscription state and purchasing, behind a protocol so the app never sees
/// RevenueCat's types directly — see CLAUDE.md sections 2 and 3.
public protocol SubscriptionProviding: Sendable {
    var isSubscribed: Bool { get async }

    /// Ties purchases to the app's anonymous ID so a reinstall can restore
    /// without an account (CLAUDE.md section 5 — no sign-in, ever).
    func configure(anonymousID: String) async

    /// Plans to show on the paywall. Throws if the store is misconfigured
    /// or unreachable so errors can be surfaced to the user.
    func availablePlans() async throws -> [SubscriptionPlan]

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
    public func availablePlans() async throws -> [SubscriptionPlan] {
        []
    }

    public func purchase(_: SubscriptionPlan) async throws {}
    public func restorePurchases() async throws {}
}
