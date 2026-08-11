import Analytics
import Core
import Foundation
import Notifications
import Persistence
import Purchases
import Testing
@testable import Features

// These cover the decision logic the screens depend on — access rules and
// paywall timing — without needing a rendered view.

private final class InMemoryRepository<Item: Codable & Sendable>: Repository, @unchecked Sendable {
    private var items: [Item] = []
    init(_ items: [Item] = []) { self.items = items }
    func loadAll() async throws -> [Item] { items }
    func save(_ items: [Item]) async throws { self.items = items }
}

private final class InMemoryStore<Value: Codable & Sendable>: ValueStore, @unchecked Sendable {
    private var value: Value
    init(_ value: Value) { self.value = value }
    func load() async -> Value { value }
    func save(_ value: Value) async throws { self.value = value }
}

private struct StubSubscription: SubscriptionProviding {
    let subscribed: Bool
    var isSubscribed: Bool { get async { subscribed } }
    func purchase(productID: String) async throws {}
    func restorePurchases() async throws {}
}

private final class RecordingAnalytics: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []
    func track(_ event: AnalyticsEvent) { events.append(event) }
}

private struct StubNotifications: NotificationScheduling {
    func requestAuthorization() async throws -> Bool { true }
    func scheduleDailyReminder(
        at time: DateComponents, identifier: String, title: String, body: String
    ) async throws {}
    func cancelReminder(identifier: String) async {}
}

@MainActor
private func makeModel(
    history: [SessionRecord] = [],
    preferences: UserPreferences = UserPreferences(),
    subscribed: Bool = false,
    freeLevelLimit: Int = 2,
    analytics: RecordingAnalytics = RecordingAnalytics()
) async -> AppModel {
    let content = ContentSchema(
        schemaVersion: 2,
        freeLevelLimit: freeLevelLimit,
        weeklySessionGoal: 5,
        levels: (1...4).map { id in
            Level(
                id: id,
                title: LocalizedText(["en": "Level \(id)"]),
                subtitle: LocalizedText(["en": "S"]),
                prepare: 5, contract: 2, hold: 0, relax: 2,
                reps: 2, sets: 1, restBetweenSets: 0
            )
        }
    )

    let model = AppModel(
        content: content,
        sessions: SessionStore(repository: InMemoryRepository(history)),
        preferences: PreferencesStore(store: InMemoryStore(preferences)),
        subscription: SubscriptionStore(provider: StubSubscription(subscribed: subscribed)),
        feedback: NoOpFeedback(),
        analytics: analytics,
        notifications: StubNotifications()
    )
    await model.load()
    return model
}

private func record(levelID: Int, completed: Bool = true) -> SessionRecord {
    SessionRecord(
        date: Date(timeIntervalSince1970: 1_767_000_000),
        levelID: levelID,
        completedReps: 10,
        plannedReps: 10,
        duration: 120,
        wasCompleted: completed
    )
}

@MainActor
struct AppModelAccessTests {

    @Test func freeLevelsAreUnlockedWithoutASubscription() async {
        let model = await makeModel(freeLevelLimit: 2)
        #expect(model.isUnlocked(levelID: 1))
        #expect(model.isUnlocked(levelID: 2))
        #expect(!model.isUnlocked(levelID: 3))
    }

    @Test func subscribingUnlocksEverything() async {
        let model = await makeModel(subscribed: true, freeLevelLimit: 2)
        #expect(model.isUnlocked(levelID: 4))
    }

    /// Progress must never lock a level — CLAUDE.md section 5 says the user
    /// may jump straight to an advanced level.
    @Test func anAdvancedLevelIsPlayableWithNoHistoryAtAll() async {
        let model = await makeModel(subscribed: true)
        #expect(model.sessions.records.isEmpty)
        #expect(model.isUnlocked(levelID: 4))
    }

    @Test func recommendationFollowsCompletedSessions() async {
        let model = await makeModel(history: [record(levelID: 2)])
        #expect(model.recommendedLevel.id == 3)
    }
}

@MainActor
struct PaywallTimingTests {

    /// CLAUDE.md section 6: the paywall appears after the first completed
    /// session, never on launch.
    @Test func paywallIsNotShownBeforeTheFirstCompletedSession() async {
        let model = await makeModel()
        #expect(!model.shouldPresentPaywall)
    }

    @Test func anAbandonedSessionDoesNotTriggerThePaywall() async {
        let model = await makeModel(history: [record(levelID: 1, completed: false)])
        #expect(!model.shouldPresentPaywall)
    }

    @Test func paywallIsShownAfterTheFirstCompletedSession() async {
        let model = await makeModel(history: [record(levelID: 1)])
        #expect(model.shouldPresentPaywall)
    }

    @Test func paywallIsShownOnlyOnce() async {
        let model = await makeModel(history: [record(levelID: 1)])
        #expect(model.shouldPresentPaywall)

        await model.markPaywallSeen()
        #expect(!model.shouldPresentPaywall)
    }

    @Test func subscribersNeverSeeThePaywall() async {
        let model = await makeModel(history: [record(levelID: 1)], subscribed: true)
        #expect(!model.shouldPresentPaywall)
    }
}

@MainActor
struct SessionRecordingTests {

    @Test func recordingASessionPersistsItAndEmitsABehaviourEvent() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 3))

        let names = analytics.events.map { $0.name }
        #expect(model.sessions.records.count == 1)
        #expect(names == ["session_completed"])
    }

    @Test func abandonedSessionsAreRecordedSeparately() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 1, completed: false))

        let names = analytics.events.map { $0.name }
        #expect(names == ["session_abandoned"])
    }

    /// The privacy promise in CLAUDE.md section 6 is only true if events stay
    /// bare — no level, no reps, no dates.
    @Test func analyticsEventsCarryNoSessionDetail() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 3))

        let allBare = analytics.events.allSatisfy { $0.parameters.isEmpty }
        #expect(allBare)
    }
}

@MainActor
struct PreferencesFlowTests {

    @Test func anonymousIDSurvivesReload() async {
        let store = InMemoryStore(UserPreferences(anonymousID: "stable-id"))
        let preferences = PreferencesStore(store: store)

        await preferences.load()
        let first = preferences.preferences.anonymousID
        await preferences.load()

        #expect(first == "stable-id")
        #expect(preferences.preferences.anonymousID == "stable-id")
    }

    @Test func completingOnboardingIsPersisted() async {
        let store = InMemoryStore(UserPreferences())
        let preferences = PreferencesStore(store: store)
        await preferences.load()

        await preferences.update { $0.hasCompletedOnboarding = true }

        let reloaded = PreferencesStore(store: store)
        await reloaded.load()
        #expect(reloaded.preferences.hasCompletedOnboarding)
    }
}
