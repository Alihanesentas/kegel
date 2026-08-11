import Testing
@testable import Purchases

struct NoOpSubscriptionProviderTests {
    @Test func alwaysReportsNotSubscribed() async {
        let provider = NoOpSubscriptionProvider()
        #expect(await provider.isSubscribed == false)
    }

    @Test func purchaseAndRestoreDoNotThrow() async throws {
        let provider = NoOpSubscriptionProvider()
        try await provider.purchase(productID: "test")
        try await provider.restorePurchases()
    }
}
