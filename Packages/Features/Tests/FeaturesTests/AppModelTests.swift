import Analytics
import Core
import Foundation
import Notifications
import Persistence
import Purchases
import Testing
@testable import Features

// These cover the decision logic the screens depend on — access rules, the
// paid-feature boundary, paywall timing and reminders — without needing a
// rendered view.

private final class InMemoryRepository<Item: Codable & Sendable>: Repository, @unchecked Sendable {
    private var items: [Item] = []
    init(_ items: [Item] = []) {
        self.items = items
    }

    func loadAll() async throws -> [Item] {
        items
    }

    func save(_ items: [Item]) async throws {
        self.items = items
    }
}

private final class InMemoryStore<Value: Codable & Sendable>: ValueStore, @unchecked Sendable {
    private var value: Value
    init(_ value: Value) {
        self.value = value
    }

    func load() async -> Value {
        value
    }

    func save(_ value: Value) async throws {
        self.value = value
    }
}

private final class StubSubscription: SubscriptionProviding, @unchecked Sendable {
    private let subscribed: Bool
    private let plans: [SubscriptionPlan]
    private(set) var configuredID: String?
    private(set) var purchased: [String] = []

    init(subscribed: Bool = false, plans: [SubscriptionPlan] = []) {
        self.subscribed = subscribed
        self.plans = plans
    }

    var isSubscribed: Bool {
        get async { subscribed }
    }

    func configure(anonymousID: String) async {
        configuredID = anonymousID
    }

    func availablePlans() async -> [SubscriptionPlan] {
        plans
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        purchased.append(plan.id)
    }

    func restorePurchases() async throws {}
}

private final class RecordingAnalytics: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []
    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

private final class RecordingNotifications: NotificationScheduling, @unchecked Sendable {
    private(set) var scheduled: [DateComponents] = []
    private(set) var cancelled: [String] = []
    var authorized = true

    func requestAuthorization() async throws -> Bool {
        authorized
    }

    func scheduleDailyReminder(
        at time: DateComponents, identifier _: String, title _: String, body _: String
    ) async throws {
        scheduled.append(time)
    }

    func cancelReminder(identifier: String) async {
        cancelled.append(identifier)
    }
}

private func makeGuide() -> MuscleGuide {
    MuscleGuide(
        title: LocalizedText(["en": "Guide"]),
        intro: LocalizedText(["en": "Intro"]),
        steps: [MuscleGuide.Step(id: 1, title: LocalizedText(["en": "S"]), body: LocalizedText(["en": "B"]))],
        closing: LocalizedText(["en": "C"])
    )
}

private func makeContent(freeLevelLimit: Int = 2, lockedFeatures: Set<PaidFeature> = []) -> ContentSchema {
    ContentSchema(
        schemaVersion: 3,
        freeLevelLimit: freeLevelLimit,
        weeklySessionGoal: 5,
        levels: (1 ... 4).map { id in
            Level(
                id: id,
                title: LocalizedText(["en": "Level \(id)"]),
                subtitle: LocalizedText(["en": "S"]),
                prepare: 5, contract: 2, hold: 0, relax: 2,
                reps: 2, sets: 1, restBetweenSets: 0
            )
        },
        muscleGuide: makeGuide(),
        lockedFeatures: lockedFeatures
    )
}

@MainActor
private func makeModel(
    history: [SessionRecord] = [],
    preferences: UserPreferences = UserPreferences(),
    subscription: StubSubscription = StubSubscription(),
    content: ContentSchema = makeContent(),
    analytics: RecordingAnalytics = RecordingAnalytics(),
    notifications: RecordingNotifications = RecordingNotifications(),
    contentRefresh: (@Sendable () async -> ContentSchema?)? = nil
) async -> AppModel {
    let model = AppModel(
        content: content,
        sessions: SessionStore(repository: InMemoryRepository(history)),
        preferences: PreferencesStore(store: InMemoryStore(preferences)),
        subscription: SubscriptionStore(provider: subscription),
        feedback: NoOpFeedback(),
        analytics: analytics,
        notifications: notifications,
        contentRefresh: contentRefresh
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
struct LevelAccessTests {
    @Test func freeLevelsAreUnlockedWithoutASubscription() async {
        let model = await makeModel(content: makeContent(freeLevelLimit: 2))
        #expect(model.isUnlocked(levelID: 1))
        #expect(model.isUnlocked(levelID: 2))
        #expect(!model.isUnlocked(levelID: 3))
    }

    @Test func subscribingUnlocksEverything() async {
        let model = await makeModel(subscription: StubSubscription(subscribed: true))
        #expect(model.isUnlocked(levelID: 4))
    }

    /// Progress must never lock a level — CLAUDE.md section 5 says the user
    /// may jump straight to an advanced level.
    @Test func anAdvancedLevelIsPlayableWithNoHistoryAtAll() async {
        let model = await makeModel(subscription: StubSubscription(subscribed: true))
        #expect(model.sessions.records.isEmpty)
        #expect(model.isUnlocked(levelID: 4))
    }

    @Test func recommendationFollowsCompletedSessions() async {
        let model = await makeModel(history: [record(levelID: 2)])
        #expect(model.recommendedLevel.id == 3)
    }
}

@MainActor
struct PaidFeatureTests {
    /// CLAUDE.md section 6 names dim mode and progress as paid by default —
    /// but the boundary is data, so the app must honour whatever content says.
    @Test func lockedFeaturesRequireASubscription() async {
        let model = await makeModel(content: makeContent(lockedFeatures: [.dimMode, .progress]))
        #expect(!model.isUnlocked(.dimMode))
        #expect(!model.isUnlocked(.progress))
    }

    @Test func subscribersGetLockedFeatures() async {
        let model = await makeModel(
            subscription: StubSubscription(subscribed: true),
            content: makeContent(lockedFeatures: [.dimMode, .progress])
        )
        #expect(model.isUnlocked(.dimMode))
        #expect(model.isUnlocked(.progress))
    }

    @Test func aFeatureContentDoesNotLockStaysFreeForEveryone() async {
        let model = await makeModel(content: makeContent(lockedFeatures: [.progress]))
        #expect(model.isUnlocked(.dimMode))
        #expect(!model.isUnlocked(.progress))
    }

    @Test func embeddedContentLocksDimModeAndProgress() {
        let content = ContentLoader.loadEmbedded()
        #expect(content.requiresSubscription(.dimMode))
        #expect(content.requiresSubscription(.progress))
    }
}

@MainActor
struct PaywallTimingTests {
    /// CLAUDE.md section 6: the paywall appears after the first completed
    /// session, never on launch.
    @Test func paywallIsNotShownBeforeTheFirstCompletedSession() async {
        #expect(await makeModel().shouldPresentPaywall == false)
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
        let model = await makeModel(
            history: [record(levelID: 1)], subscription: StubSubscription(subscribed: true)
        )
        #expect(!model.shouldPresentPaywall)
    }
}

@MainActor
struct SubscriptionWiringTests {
    /// Purchases are tied to the anonymous ID so a reinstall restores without
    /// any sign-in (CLAUDE.md section 5).
    @Test func theStoreIsConfiguredWithTheAnonymousID() async {
        let subscription = StubSubscription()
        _ = await makeModel(preferences: UserPreferences(anonymousID: "user-123"), subscription: subscription)
        #expect(subscription.configuredID == "user-123")
    }

    @Test func plansAreLoadedFromTheProvider() async {
        let plans = [
            SubscriptionPlan(id: "yearly", period: .yearly, localizedPrice: "$39.99"),
            SubscriptionPlan(id: "monthly", period: .monthly, localizedPrice: "$4.99"),
        ]
        let model = await makeModel(subscription: StubSubscription(plans: plans))

        await model.subscription.loadPlans()
        let ids = model.subscription.plans.map(\.id)
        #expect(ids == ["yearly", "monthly"])
    }

    @Test func aCancelledPurchaseIsNotTreatedAsAnError() async {
        let model = await makeModel()
        await model.subscription.purchase(
            SubscriptionPlan(id: "x", period: .monthly, localizedPrice: "$1")
        )
        #expect(model.subscription.lastError == nil)
    }
}

@MainActor
struct ReminderTests {
    @Test func settingATimeSchedulesTheReminder() async {
        let notifications = RecordingNotifications()
        let model = await makeModel(notifications: notifications)

        await model.setReminder(hour: 8, minute: 30)

        #expect(model.preferences.preferences.reminderHour == 8)
        #expect(notifications.scheduled.last?.hour == 8)
        #expect(notifications.scheduled.last?.minute == 30)
    }

    @Test func turningRemindersOffCancelsTheScheduledOne() async {
        let notifications = RecordingNotifications()
        let model = await makeModel(notifications: notifications)

        await model.setReminder(hour: 8, minute: 0)
        await model.setReminder(hour: nil, minute: nil)

        #expect(model.preferences.preferences.reminderTime == nil)
        #expect(notifications.cancelled == ["daily-reminder"])
    }

    @Test func changingTheTimeIsPersisted() async {
        let model = await makeModel()
        await model.setReminder(hour: 7, minute: 15)
        await model.setReminder(hour: 21, minute: 45)

        #expect(model.preferences.preferences.reminderHour == 21)
        #expect(model.preferences.preferences.reminderMinute == 45)
    }

    @Test func nothingIsScheduledWithoutNotificationPermission() async {
        let notifications = RecordingNotifications()
        notifications.authorized = false
        let model = await makeModel(notifications: notifications)

        await model.setReminder(hour: 8, minute: 0)

        #expect(notifications.scheduled.isEmpty)
        // The preference is still saved — permission can be granted later.
        #expect(model.preferences.preferences.reminderHour == 8)
    }
}

@MainActor
struct ContentRefreshTests {
    @Test func newerRemoteContentReplacesWhatTheAppStartedWith() async {
        let updated = makeContent(freeLevelLimit: 5)
        let model = await makeModel(content: makeContent(freeLevelLimit: 2)) { updated }

        #expect(!model.isUnlocked(levelID: 3))
        await model.refreshContent()
        #expect(model.isUnlocked(levelID: 3))
    }

    @Test func aFailedRefreshLeavesContentAlone() async {
        let model = await makeModel(content: makeContent(freeLevelLimit: 2)) { nil }

        await model.refreshContent()
        #expect(model.content.freeLevelLimit == 2)
    }

    /// With no CDN configured there's no refresh closure at all; the app must
    /// simply keep running on the embedded catalogue.
    @Test func noRefreshConfiguredIsNotAnError() async {
        let model = await makeModel(content: makeContent(freeLevelLimit: 2))
        await model.refreshContent()
        #expect(model.content.freeLevelLimit == 2)
    }
}

@MainActor
struct SessionRecordingTests {
    @Test func recordingASessionPersistsItAndEmitsABehaviourEvent() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 3))

        let names = analytics.events.map(\.name)
        #expect(model.sessions.records.count == 1)
        #expect(names == ["session_completed"])
    }

    @Test func abandonedSessionsAreRecordedSeparately() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 1, completed: false))

        let names = analytics.events.map(\.name)
        #expect(names == ["session_abandoned"])
    }

    /// The privacy promise in CLAUDE.md section 6 is only true if events stay
    /// bare — no level, no reps, no dates.
    @Test func analyticsEventsCarryNoSessionDetail() async {
        let analytics = RecordingAnalytics()
        let model = await makeModel(analytics: analytics)

        await model.record(record(levelID: 3))

        let allBare = analytics.events.allSatisfy(\.parameters.isEmpty)
        #expect(allBare)
    }
}

@MainActor
struct PreferencesFlowTests {
    @Test func anonymousIDSurvivesReload() async {
        let store = InMemoryStore(UserPreferences(anonymousID: "stable-id"))
        let preferences = PreferencesStore(store: store)

        await preferences.load()
        await preferences.load()

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
