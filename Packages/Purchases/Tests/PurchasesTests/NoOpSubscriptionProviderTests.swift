import Testing
@testable import Purchases

// The RevenueCat-backed provider can't be tested without a configured store
// and a signed build, so these cover the protocol contract and the value types
// the paywall renders from.

struct NoOpSubscriptionProviderTests {

    @Test func alwaysReportsNotSubscribed() async {
        #expect(await NoOpSubscriptionProvider().isSubscribed == false)
    }

    @Test func offersNothingToBuy() async {
        #expect(await NoOpSubscriptionProvider().availablePlans().isEmpty)
    }

    @Test func purchaseAndRestoreDoNotThrow() async throws {
        let provider = NoOpSubscriptionProvider()
        await provider.configure(anonymousID: "test")
        try await provider.purchase(SubscriptionPlan(id: "x", period: .monthly, localizedPrice: "$1"))
        try await provider.restorePurchases()
    }
}

struct SubscriptionPlanTests {

    @Test func monthlyPlansCarryNoPerMonthBreakdown() {
        let plan = SubscriptionPlan(id: "m", period: .monthly, localizedPrice: "$4.99")
        #expect(plan.localizedMonthlyEquivalent == nil)
    }

    @Test func yearlyPlansCanShowAPerMonthBreakdown() {
        let plan = SubscriptionPlan(
            id: "y", period: .yearly, localizedPrice: "$39.99", localizedMonthlyEquivalent: "$3.33"
        )
        #expect(plan.localizedMonthlyEquivalent == "$3.33")
    }

    @Test func planIdentityIsTheStoreProductIdentifier() {
        #expect(SubscriptionPlan(id: "com.app.yearly", period: .yearly, localizedPrice: "x").id == "com.app.yearly")
    }

    @Test func bothBillingPeriodsAreModelled() {
        #expect(SubscriptionPlan.Period.allCases.count == 2)
    }
}
