import Analytics
import Core
import Features
import Feedback
import Foundation
import Notifications
import Persistence
import Purchases

/// Composition root. The one place that names concrete implementations —
/// everything below this sees only protocols (CLAUDE.md section 3).
enum AppEnvironment {

    @MainActor
    static func makeModel() -> AppModel {
        AppModel(
            content: ContentLoader.loadEmbedded(),
            sessions: SessionStore(
                repository: JSONFileRepository<SessionRecord>(fileURL: fileURL("sessions.json"))
            ),
            preferences: PreferencesStore(
                store: JSONFileStore(fileURL: fileURL("preferences.json")) { UserPreferences() }
            ),
            subscription: SubscriptionStore(
                // Real RevenueCat wiring is M3: it needs an API key and
                // products configured in App Store Connect. Until then this
                // reports "not subscribed" and purchases are no-ops.
                provider: NoOpSubscriptionProvider()
            ),
            feedback: FeedbackManager(),
            // Real SDK wiring is M5; the protocol and event list are already
            // in place so screens don't change when it lands.
            analytics: NoOpAnalyticsTracker(),
            notifications: LocalNotificationScheduler()
        )
    }

    /// Session history and preferences live in Application Support — user
    /// data, not caches, and never synced anywhere (CLAUDE.md section 6).
    private static func fileURL(_ name: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(name)
    }
}
