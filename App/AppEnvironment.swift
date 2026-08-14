import Analytics
import Core
import Features
import Feedback
import Foundation
import Notifications
import Persistence
import Purchases
import RemoteContent

/// Composition root. The one place that names concrete implementations —
/// everything below this sees only protocols (CLAUDE.md section 3).
enum AppEnvironment {
    @MainActor
    static func makeModel() -> AppModel {
        let remoteContent = AppConfiguration.remoteContentURL.map { url in
            RemoteContentStore(remoteURL: url, cacheFileURL: fileURL("content-cache.json"))
        }

        return AppModel(
            // Always start from the embedded copy so launch never waits on
            // disk or network. `refreshContent()` swaps in the cached or newly
            // fetched file moments later if there's a valid newer one
            // (CLAUDE.md section 5).
            content: ContentLoader.loadEmbedded(),
            sessions: SessionStore(
                repository: JSONFileRepository<SessionRecord>(fileURL: fileURL("sessions.json"))
            ),
            preferences: PreferencesStore(
                store: JSONFileStore(fileURL: fileURL("preferences.json")) { UserPreferences() }
            ),
            subscription: SubscriptionStore(provider: makeSubscriptionProvider()),
            feedback: FeedbackManager(),
            // Real SDK wiring is M5; the protocol and event list are already
            // in place so screens don't change when it lands.
            analytics: NoOpAnalyticsTracker(),
            notifications: LocalNotificationScheduler(),
            contentRefresh: remoteContent.map { store in
                { @Sendable in
                    await store.refresh()
                    return await store.currentContent()
                }
            }
        )
    }

    /// Purchasing is only live once a RevenueCat key is configured. Without
    /// one the app reports "not subscribed" and shows no plans, rather than
    /// pretending to sell something it can't deliver.
    private static func makeSubscriptionProvider() -> any SubscriptionProviding {
        let key = AppConfiguration.revenueCatAPIKey
        guard !key.isEmpty else { return NoOpSubscriptionProvider() }
        return RevenueCatSubscriptionProvider(apiKey: key, entitlementID: AppConfiguration.entitlementID)
    }

    /// Session history and preferences live in Application Support — user
    /// data, not caches, and never synced anywhere (CLAUDE.md section 6).
    private static func fileURL(_ name: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(name)
    }
}
