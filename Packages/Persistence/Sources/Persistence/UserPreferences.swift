import Foundation

/// Everything the app remembers about *how the user set things up* — as
/// opposed to what they did, which lives in session records.
///
/// There is no account and no login (CLAUDE.md section 5, "Kimlik"): the
/// anonymous ID is generated on first launch, shown in Settings for support,
/// and is what will later be handed to RevenueCat as its App User ID.
public struct UserPreferences: Codable, Equatable, Sendable {
    public var anonymousID: String
    public var hasCompletedOnboarding: Bool
    public var hasSeenPaywall: Bool
    public var selectedLevelID: Int?
    /// Local time of day for the daily reminder; `nil` means reminders are off.
    public var reminderHour: Int?
    public var reminderMinute: Int?

    public init(
        anonymousID: String = UUID().uuidString,
        hasCompletedOnboarding: Bool = false,
        hasSeenPaywall: Bool = false,
        selectedLevelID: Int? = nil,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.anonymousID = anonymousID
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasSeenPaywall = hasSeenPaywall
        self.selectedLevelID = selectedLevelID
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    public var reminderTime: DateComponents? {
        guard let reminderHour else { return nil }
        return DateComponents(hour: reminderHour, minute: reminderMinute ?? 0)
    }

    public mutating func setReminder(hour: Int?, minute: Int?) {
        reminderHour = hour
        reminderMinute = minute
    }
}
