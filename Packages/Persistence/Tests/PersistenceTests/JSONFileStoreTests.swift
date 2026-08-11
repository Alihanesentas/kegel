import Foundation
import Testing
@testable import Persistence

struct JSONFileStoreTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("prefs.json")
    }

    @Test func missingFileYieldsTheDefault() async {
        let store = JSONFileStore(fileURL: tempFileURL()) { UserPreferences(anonymousID: "fallback") }
        #expect(await store.load().anonymousID == "fallback")
    }

    @Test func saveThenLoadRoundTrips() async throws {
        let url = tempFileURL()
        let store = JSONFileStore(fileURL: url) { UserPreferences() }

        var preferences = UserPreferences(anonymousID: "abc")
        preferences.hasCompletedOnboarding = true
        preferences.setReminder(hour: 9, minute: 30)
        try await store.save(preferences)

        let loaded = await store.load()
        #expect(loaded == preferences)
        #expect(loaded.reminderTime?.hour == 9)

        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// A corrupt preferences file must not stop the app from launching.
    @Test func corruptFileYieldsTheDefaultRatherThanThrowing() async throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("{ not json".utf8).write(to: url)

        let store = JSONFileStore(fileURL: url) { UserPreferences(anonymousID: "fallback") }
        #expect(await store.load().anonymousID == "fallback")

        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

struct UserPreferencesTests {

    @Test func remindersAreOffWhenNoHourIsSet() {
        #expect(UserPreferences().reminderTime == nil)
    }

    @Test func clearingTheReminderTurnsItOff() {
        var preferences = UserPreferences()
        preferences.setReminder(hour: 8, minute: 0)
        #expect(preferences.reminderTime != nil)

        preferences.setReminder(hour: nil, minute: nil)
        #expect(preferences.reminderTime == nil)
    }

    @Test func eachInstallGetsItsOwnAnonymousID() {
        #expect(UserPreferences().anonymousID != UserPreferences().anonymousID)
    }
}
