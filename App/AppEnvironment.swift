import Analytics
import Core
import Feedback
import Foundation
import Notifications
import Observation
import Persistence
import Purchases

/// Where the app's dependencies are assembled. Everything below `App` only
/// ever sees protocols (`FeedbackEmitting`, `SubscriptionProviding`, ...) —
/// concrete implementations are chosen once, here.
@MainActor
@Observable
final class AppEnvironment {
    let feedback: FeedbackEmitting
    let subscriptions: SubscriptionProviding
    let analytics: AnalyticsTracking
    let notifications: NotificationScheduling
    let sessionRepository: any Repository<SessionRecord>

    private(set) var content: ContentSchema

    init() {
        feedback = FeedbackManager()
        subscriptions = NoOpSubscriptionProvider() // real RevenueCat wiring is M3
        analytics = NoOpAnalyticsTracker() // real SDK wiring is M5
        notifications = LocalNotificationScheduler()

        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        sessionRepository = JSONFileRepository<SessionRecord>(
            fileURL: supportDirectory.appendingPathComponent("sessions.json")
        )

        // RemoteContent isn't wired in yet — the CDN URL for content.json hasn't
        // been decided (M3). Until then the app always uses the embedded catalog.
        content = ContentLoader.loadEmbedded()
    }

    func makeEngine(levelID: Int) -> WorkoutEngine {
        let level = content.level(id: levelID) ?? content.levels[0]
        return WorkoutEngine(level: level, feedback: feedback)
    }
}
