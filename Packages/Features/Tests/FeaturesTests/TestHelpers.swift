import Analytics
import Core
import Foundation
import Notifications
import Persistence
import Purchases
@testable import Features

final class InMemoryRepository<Item: Codable & Sendable>: Repository, @unchecked Sendable {
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

final class InMemoryStore<Value: Codable & Sendable>: ValueStore, @unchecked Sendable {
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

final class StubSubscription: SubscriptionProviding, @unchecked Sendable {
    private let subscribed: Bool
    private let plans: [SubscriptionPlan]
    private(set) var configuredID: String?
    private(set) var purchased: [String] = []

    var shouldFailLoadPlans = false
    var shouldFailPurchase = false
    var loadPlansError: Error?
    var purchaseError: Error?

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

    func availablePlans() async throws -> [SubscriptionPlan] {
        if shouldFailLoadPlans {
            throw loadPlansError ?? SubscriptionError.failed("Plans load failed")
        }
        return plans
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        if shouldFailPurchase {
            throw purchaseError ?? SubscriptionError.failed("Purchase failed")
        }
        purchased.append(plan.id)
    }

    func restorePurchases() async throws {}
}

final class RecordingAnalytics: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []
    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

final class RecordingNotifications: NotificationScheduling, @unchecked Sendable {
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

final class RecordingFeedback: FeedbackEmitting, @unchecked Sendable {
    private(set) var vibrationEnabledCalls: [Bool] = []

    func prepare() {}
    func cue(for _: Phase, duration _: Double) {}
    func countdownTick() {}
    func setVibrationEnabled(_ enabled: Bool) {
        vibrationEnabledCalls.append(enabled)
    }
}

func makeGuide() -> MuscleGuide {
    MuscleGuide(
        title: LocalizedText(["en": "Guide"]),
        intro: LocalizedText(["en": "Intro"]),
        steps: [MuscleGuide.Step(id: 1, title: LocalizedText(["en": "S"]), body: LocalizedText(["en": "B"]))],
        closing: LocalizedText(["en": "C"])
    )
}

func makeContent(freeLevelLimit: Int = 2, lockedFeatures: Set<PaidFeature> = []) -> ContentSchema {
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
func makeModel(
    history: [SessionRecord] = [],
    preferences: UserPreferences = UserPreferences(),
    subscription: StubSubscription = StubSubscription(),
    content: ContentSchema = makeContent(),
    analytics: RecordingAnalytics = RecordingAnalytics(),
    notifications: RecordingNotifications = RecordingNotifications(),
    feedback: any FeedbackEmitting = NoOpFeedback(),
    contentRefresh: (@Sendable () async -> ContentSchema?)? = nil
) async -> AppModel {
    let model = AppModel(
        content: content,
        sessions: SessionStore(repository: InMemoryRepository(history)),
        preferences: PreferencesStore(store: InMemoryStore(preferences)),
        subscription: SubscriptionStore(provider: subscription),
        feedback: feedback,
        analytics: analytics,
        notifications: notifications,
        contentRefresh: contentRefresh
    )
    await model.load()
    return model
}

func record(levelID: Int, completed: Bool = true) -> SessionRecord {
    SessionRecord(
        date: Date(timeIntervalSince1970: 1_767_000_000),
        levelID: levelID,
        completedReps: 10,
        plannedReps: 10,
        duration: 120,
        wasCompleted: completed
    )
}
