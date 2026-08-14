import Foundation
@testable import Purchases

/// Test double for ``SubscriptionProviding`` that simulates various purchase scenarios
/// without hitting the real RevenueCat API.
actor MockSubscriptionProvider: SubscriptionProviding {
    /// What this mock should do on the next purchase() call.
    enum PurchaseScenario {
        case success
        case userCancelled
        case networkError(String)
        case invalidReceipt(String)
    }

    var scenario: PurchaseScenario = .success
    var configuredAnonymousID: String?
    var isSubscribed = false
    var availablePlansMock: [SubscriptionPlan] = [
        SubscriptionPlan(
            identifier: "pro_monthly",
            displayName: "Pro Monthly",
            price: 9.99,
            currencyCode: "USD"
        ),
        SubscriptionPlan(
            identifier: "pro_annual",
            displayName: "Pro Annual",
            price: 79.99,
            currencyCode: "USD"
        ),
    ]

    func configure(anonymousID: String) async {
        configuredAnonymousID = anonymousID
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        switch scenario {
        case .success:
            isSubscribed = true
        case .userCancelled:
            throw SubscriptionError.cancelled
        case .networkError(let message):
            throw SubscriptionError.failed(message)
        case .invalidReceipt(let message):
            throw SubscriptionError.failed(message)
        }
    }

    func restorePurchases() async throws {
        // In a real scenario, this would validate the App Store receipt
        // For testing, we just set isSubscribed to true to simulate a successful restore
        isSubscribed = true
    }

    var entitlementID: String {
        "pro"
    }

    func availablePlans() async -> [SubscriptionPlan] {
        availablePlansMock
    }

    var entitlements: [String: [String: Any]] {
        [
            "pro": [
                "identifier": "pro",
                "isActive": isSubscribed,
                "expirationDate": Date().addingTimeInterval(86400 * 365).iso8601String,
            ]
        ]
    }

    func fetchEntitlements() async -> String? {
        isSubscribed ? "pro" : nil
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
