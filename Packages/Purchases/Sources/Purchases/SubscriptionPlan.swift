import Foundation

/// A purchasable subscription, already formatted for display.
///
/// Prices arrive as store-localized strings rather than numbers: currency,
/// separators and placement differ per storefront, and StoreKit already knows
/// the right answer. Formatting them ourselves would get it wrong somewhere.
public struct SubscriptionPlan: Identifiable, Equatable, Sendable {
    public enum Period: String, Sendable, CaseIterable {
        case monthly
        case yearly
    }

    /// The store product identifier.
    public let id: String
    public let period: Period
    /// e.g. "₺249,99" — localized by the store.
    public let localizedPrice: String
    /// Price broken down per month, for the yearly plan. `nil` when it would
    /// just repeat `localizedPrice`.
    public let localizedMonthlyEquivalent: String?

    public init(
        id: String,
        period: Period,
        localizedPrice: String,
        localizedMonthlyEquivalent: String? = nil
    ) {
        self.id = id
        self.period = period
        self.localizedPrice = localizedPrice
        self.localizedMonthlyEquivalent = localizedMonthlyEquivalent
    }
}

public enum SubscriptionError: Error, Equatable {
    /// The user dismissed the store sheet. Not a failure worth reporting.
    case cancelled
    case notConfigured
    case failed(String)
}
