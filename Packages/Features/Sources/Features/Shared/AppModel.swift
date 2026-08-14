import Analytics
import Core
import Foundation
import Notifications
import Observation
import Purchases

/// The object every screen reads from. Assembled once by the app target and
/// handed down through the SwiftUI environment.
///
/// Screens see this and the protocols it exposes — never a concrete SDK.
@MainActor
@Observable
public final class AppModel {
    /// Starts as the embedded catalogue and is replaced if a newer, valid
    /// remote version arrives (CLAUDE.md section 5).
    public private(set) var content: ContentSchema

    public let sessions: SessionStore
    public let preferences: PreferencesStore
    public let subscription: SubscriptionStore
    public let feedback: FeedbackEmitting
    public let analytics: any AnalyticsTracking
    public let notifications: any NotificationScheduling

    private let contentRefresh: (@Sendable () async -> ContentSchema?)?

    public init(
        content: ContentSchema,
        sessions: SessionStore,
        preferences: PreferencesStore,
        subscription: SubscriptionStore,
        feedback: FeedbackEmitting,
        analytics: any AnalyticsTracking,
        notifications: any NotificationScheduling,
        contentRefresh: (@Sendable () async -> ContentSchema?)? = nil
    ) {
        self.content = content
        self.sessions = sessions
        self.preferences = preferences
        self.subscription = subscription
        self.feedback = feedback
        self.analytics = analytics
        self.notifications = notifications
        self.contentRefresh = contentRefresh

        // "Subscription Build" (see SubscriptionBuildConfiguration.swift): a
        // compile-time-only configuration used for App Store review and
        // demos, where every level and paid feature must be reachable and no
        // paywall ever appears. `setSubscriptionBuild()` also stops later
        // calls to `subscription.configure(anonymousID:)` in `load()` from
        // overwriting this with the real (unsubscribed) entitlement state.
        if SubscriptionBuildConfiguration.isSubscriptionBuild {
            subscription.setSubscriptionBuild()
        }
    }

    public func load() async {
        await sessions.load()
        await preferences.load()
        // The store needs the anonymous ID before it can report entitlements,
        // so this has to come after preferences are loaded.
        await subscription.configure(anonymousID: preferences.preferences.anonymousID)
    }

    /// Fetches newer content in the background. Never blocks the UI and never
    /// fails visibly — a bad or unreachable file just leaves things as they are.
    public func refreshContent() async {
        guard let contentRefresh, let updated = await contentRefresh() else { return }
        content = updated
    }

    // MARK: Access

    /// A level is playable when it's within the free tier or the user subscribes.
    /// Progress never locks a level — CLAUDE.md section 5.
    ///
    /// In a "Subscription Build" this returns `true` unconditionally,
    /// resolved entirely at compile time — see
    /// `SubscriptionBuildConfiguration.swift`.
    public func isUnlocked(levelID: Int) -> Bool {
        if SubscriptionBuildConfiguration.isSubscriptionBuild { return true }
        return content.isFree(levelID: levelID) || subscription.isSubscribed
    }

    /// Whether a paid feature is available right now. Which features are paid
    /// comes from `content.json`, not from code (CLAUDE.md section 6).
    ///
    /// In a "Subscription Build" this returns `true` unconditionally,
    /// resolved entirely at compile time — see
    /// `SubscriptionBuildConfiguration.swift`.
    public func isUnlocked(_ feature: PaidFeature) -> Bool {
        if SubscriptionBuildConfiguration.isSubscriptionBuild { return true }
        return !content.requiresSubscription(feature) || subscription.isSubscribed
    }

    public func makeEngine(for level: Level) -> WorkoutEngine {
        WorkoutEngine(level: level, feedback: feedback)
    }

    public var recommendedLevel: Level {
        let id = sessions.recommendedLevelID(in: content)
        return content.level(id: id) ?? content.levels[0]
    }

    /// The paywall is shown *after* the first completed session, never on
    /// launch — CLAUDE.md section 6.
    public var shouldPresentPaywall: Bool {
        !subscription.isSubscribed
            && sessions.hasCompletedASession
            && !preferences.preferences.hasSeenPaywall
    }

    public func markPaywallSeen() async {
        await preferences.update { $0.hasSeenPaywall = true }
    }

    // MARK: Reminders

    private static let reminderIdentifier = "daily-reminder"

    /// Schedules (or clears) the daily reminder to match saved preferences.
    ///
    /// Notifications only remind — they can't run a session (CLAUDE.md
    /// section 7) — and they're local, never remote push (section 6).
    public func scheduleReminder() async {
        guard let time = preferences.preferences.reminderTime else {
            await notifications.cancelReminder(identifier: Self.reminderIdentifier)
            return
        }
        guard await (try? notifications.requestAuthorization()) == true else { return }

        // Replaces any existing request with the same identifier.
        // `.main`, not `.module`: the catalog ships with the app target — see
        // the comment in Package.swift.
        try? await notifications.scheduleDailyReminder(
            at: time,
            identifier: Self.reminderIdentifier,
            title: String(localized: "reminder.title", bundle: .main),
            body: String(localized: "reminder.body", bundle: .main)
        )
    }

    /// Saves a new reminder time (or turns reminders off) and re-registers it.
    public func setReminder(hour: Int?, minute: Int?) async {
        await preferences.update { $0.setReminder(hour: hour, minute: minute) }
        await scheduleReminder()
    }

    public func record(_ record: SessionRecord) async {
        await sessions.add(record)
        analytics.track(record.wasCompleted ? .sessionCompleted : .sessionAbandoned)
    }
}
