import Foundation
import RevenueCat

/// The real implementation, and the only file in the codebase that imports
/// RevenueCat (CLAUDE.md section 3).
///
/// Why RevenueCat at all: StoreKit 2 handles the purchase on-device fine, but
/// renewals, cancellations and refunds arrive as App Store Server Notifications
/// to a server we don't have. This buys that instead of us building it
/// (CLAUDE.md section 2).
public actor RevenueCatSubscriptionProvider: SubscriptionProviding {
    /// Entitlement identifier configured in the RevenueCat dashboard. Every
    /// paid plan must grant this one entitlement — the app only ever asks
    /// "is it active", never "which product did they buy".
    private let entitlementID: String
    private let apiKey: String
    private var isConfigured = false

    public init(apiKey: String, entitlementID: String = "pro") {
        self.apiKey = apiKey
        self.entitlementID = entitlementID
    }

    public func configure(anonymousID: String) async {
        guard !isConfigured, !apiKey.isEmpty else { return }
        // The app's own anonymous ID becomes the RevenueCat App User ID, so a
        // reinstall on the same device restores without any sign-in.
        Purchases.configure(withAPIKey: apiKey, appUserID: anonymousID)
        isConfigured = true
    }

    public var isSubscribed: Bool {
        get async {
            guard isConfigured else { return false }
            guard let info = try? await Purchases.shared.customerInfo() else { return false }
            return info.entitlements[entitlementID]?.isActive == true
        }
    }

    public func availablePlans() async -> [SubscriptionPlan] {
        guard isConfigured,
              let offerings = try? await Purchases.shared.offerings(),
              let current = offerings.current
        else {
            return []
        }

        let plans = current.availablePackages.compactMap(Self.plan(from:))
        // Yearly first: it's the better value and the one worth defaulting to.
        return plans.sorted { lhs, _ in lhs.period == .yearly }
    }

    public func purchase(_ plan: SubscriptionPlan) async throws {
        guard isConfigured else { throw SubscriptionError.notConfigured }
        guard let package = await package(for: plan) else {
            throw SubscriptionError.failed("Product \(plan.id) is not in the current offering")
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                throw SubscriptionError.cancelled
            }
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.failed(error.localizedDescription)
        }
    }

    public func restorePurchases() async throws {
        guard isConfigured else { throw SubscriptionError.notConfigured }
        do {
            _ = try await Purchases.shared.restorePurchases()
        } catch {
            throw SubscriptionError.failed(error.localizedDescription)
        }
    }

    // MARK: Mapping

    private func package(for plan: SubscriptionPlan) async -> Package? {
        guard let offerings = try? await Purchases.shared.offerings() else { return nil }
        return offerings.current?.availablePackages.first { $0.storeProduct.productIdentifier == plan.id }
    }

    private static func plan(from package: Package) -> SubscriptionPlan? {
        guard let period = period(of: package) else { return nil }
        let product = package.storeProduct

        return SubscriptionPlan(
            id: product.productIdentifier,
            period: period,
            localizedPrice: product.localizedPriceString,
            localizedMonthlyEquivalent: period == .yearly ? monthlyEquivalent(of: product) : nil
        )
    }

    private static func period(of package: Package) -> SubscriptionPlan.Period? {
        switch package.packageType {
        case .monthly: .monthly
        case .annual: .yearly
        // Weekly, lifetime and custom packages aren't part of the offer we
        // sell; showing them would contradict the paywall copy.
        default: nil
        }
    }

    /// "…/month" figure for the yearly plan, formatted in the product's own
    /// currency and locale.
    private static func monthlyEquivalent(of product: StoreProduct) -> String? {
        let monthly = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.currencyCode
        formatter.locale = product.sk2Product?.priceFormatStyle.locale ?? .current
        return formatter.string(from: monthly as NSDecimalNumber)
    }
}
