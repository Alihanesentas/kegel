import Purchases
import Testing
@testable import Features

@MainActor
struct PurchaseFlowTests {
    /// Successful purchase flow: user clicks button → StoreKit dialog →
    /// RevenueCat validates → subscription state updates → paywall closes.
    @Test func successfulPurchaseUnlocksSubscribedFeatures() async {
        let subscription = StubSubscription(plans: [
            SubscriptionPlan(id: "pro_monthly", period: .monthly, localizedPrice: "$9.99")
        ])
        var model = await makeModel(subscription: subscription)

        #expect(!model.subscription.isSubscribed)
        await model.subscription.loadPlans()
        guard let plan = model.subscription.plans.first else {
            Issue.record("No plans loaded")
            return
        }

        await model.subscription.purchase(plan)
        #expect(model.subscription.isSubscribed)
        #expect(model.subscription.lastError == nil)
    }

    /// Network error or invalid receipt — error is recorded, subscription unchanged.
    @Test func purchaseErrorIsRecordedButDoesNotUnlock() async {
        let plan = SubscriptionPlan(id: "pro_monthly", period: .monthly, localizedPrice: "$9.99")
        let subscription = StubSubscription(plans: [plan])
        subscription.shouldFailPurchase = true
        subscription.purchaseError = SubscriptionError.failed("Network error")
        let model = await makeModel(subscription: subscription)

        #expect(!model.subscription.isSubscribed)

        await model.subscription.purchase(plan)

        #expect(!model.subscription.isSubscribed)
        #expect(model.subscription.lastError != nil)
    }

    @Test func loadPlansNetworkErrorIsRecorded() async {
        let subscription = StubSubscription()
        subscription.shouldFailLoadPlans = true
        subscription.loadPlansError = SubscriptionError.failed("Network unreachable")
        let model = await makeModel(subscription: subscription)

        await model.subscription.loadPlans()

        #expect(model.subscription.lastError != nil)
        #expect(model.subscription.plans.isEmpty)
    }

    @Test func purchaseCancelledByUserIsNotRecordedAsError() async {
        let plan = SubscriptionPlan(id: "pro_monthly", period: .monthly, localizedPrice: "$9.99")
        let subscription = StubSubscription(plans: [plan])
        subscription.shouldFailPurchase = true
        subscription.purchaseError = SubscriptionError.cancelled
        let model = await makeModel(subscription: subscription)

        await model.subscription.purchase(plan)

        #expect(!model.subscription.isSubscribed)
        #expect(model.subscription.lastError == nil)
    }

    /// Paywall should not show when user is already subscribed.
    @Test func subscribedUsersNeverSeePaywall() async {
        let model = await makeModel(
            history: [record(levelID: 1)],
            subscription: StubSubscription(subscribed: true)
        )

        #expect(!model.shouldPresentPaywall)
    }

    /// After marking paywall seen, it should not reappear until subscription state
    /// changes or history is cleared.
    @Test func paywallOnlyShowsUntilMarkedAsSeen() async {
        let model = await makeModel(history: [record(levelID: 1)])

        #expect(model.shouldPresentPaywall)
        await model.markPaywallSeen()
        #expect(!model.shouldPresentPaywall)
    }
}
