import Foundation
import Testing
@testable import Notifications

// `LocalNotificationScheduler` wraps UNUserNotificationCenter, which needs a
// real app bundle/entitlements to authorize — not exercised here. This checks
// the protocol contract instead, against a fake that doesn't touch the OS.
private final class RecordingScheduler: NotificationScheduling, @unchecked Sendable {
    private(set) var scheduled: [String] = []

    func requestAuthorization() async throws -> Bool { true }

    func scheduleDailyReminder(at time: DateComponents, identifier: String, title: String, body: String) async throws {
        scheduled.append(identifier)
    }

    func cancelReminder(identifier: String) async {
        scheduled.removeAll { $0 == identifier }
    }
}

struct NotificationSchedulingTests {
    @Test func schedulingThenCancelingTracksIdentifiers() async throws {
        let scheduler = RecordingScheduler()

        try await scheduler.scheduleDailyReminder(
            at: DateComponents(hour: 9), identifier: "daily-reminder", title: "T", body: "B"
        )
        #expect(scheduler.scheduled == ["daily-reminder"])

        await scheduler.cancelReminder(identifier: "daily-reminder")
        #expect(scheduler.scheduled.isEmpty)
    }
}
