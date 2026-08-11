import Foundation

/// Local reminders only — CLAUDE.md section 6: no remote push. Notifications
/// remind the user, they never drive a session (section 7).
public protocol NotificationScheduling: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleDailyReminder(at time: DateComponents, identifier: String, title: String, body: String) async throws
    func cancelReminder(identifier: String) async
}
