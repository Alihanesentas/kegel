import Analytics
import Core
import Foundation
import Notifications
import Observation

/// The object every screen reads from. Assembled once by the app target and
/// handed down through the SwiftUI environment.
///
/// Screens see this and the protocols it exposes — never a concrete SDK.
@MainActor
@Observable
public final class AppModel {
    public let content: ContentSchema
    public let sessions: SessionStore
    public let preferences: PreferencesStore
    public let subscription: SubscriptionStore
    public let feedback: FeedbackEmitting
    public let analytics: any AnalyticsTracking
    public let notifications: any NotificationScheduling

    public init(
        content: ContentSchema,
        sessions: SessionStore,
        preferences: PreferencesStore,
        subscription: SubscriptionStore,
        feedback: FeedbackEmitting,
        analytics: any AnalyticsTracking,
        notifications: any NotificationScheduling
    ) {
        self.content = content
        self.sessions = sessions
        self.preferences = preferences
        self.subscription = subscription
        self.feedback = feedback
        self.analytics = analytics
        self.notifications = notifications
    }

    public func load() async {
        await sessions.load()
        await preferences.load()
        await subscription.refresh()
    }

    // MARK: Access

    /// A level is playable when it's within the free tier or the user subscribes.
    /// Progress never locks a level — CLAUDE.md section 5.
    public func isUnlocked(levelID: Int) -> Bool {
        content.isFree(levelID: levelID) || subscription.isSubscribed
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

    /// Schedules (or clears) the daily reminder to match saved preferences.
    ///
    /// Notifications only remind — they can't run a session (CLAUDE.md
    /// section 7) — and they're local, never remote push (section 6).
    public func scheduleReminder() async {
        let identifier = "daily-reminder"
        guard let time = preferences.preferences.reminderTime else {
            await notifications.cancelReminder(identifier: identifier)
            return
        }
        guard (try? await notifications.requestAuthorization()) == true else { return }

        try? await notifications.scheduleDailyReminder(
            at: time,
            identifier: identifier,
            title: String(localized: "reminder.title", bundle: .module),
            body: String(localized: "reminder.body", bundle: .module)
        )
    }

    public func record(_ record: SessionRecord) async {
        await sessions.add(record)
        analytics.track(record.wasCompleted ? .sessionCompleted : .sessionAbandoned)
    }
}
