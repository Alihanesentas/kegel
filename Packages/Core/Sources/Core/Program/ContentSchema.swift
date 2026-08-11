import Foundation

/// Versioned shape of `content.json`. Level parameters, copy and the
/// free/paid boundary all live here rather than in Swift — see CLAUDE.md
/// section 5 and section 6 ("Ücretsiz/ücretli sınırı content.json'dan gelir").
public struct ContentSchema: Codable, Sendable {
    public let schemaVersion: Int
    /// Levels with `id` at or below this are free; the rest need a subscription.
    public let freeLevelLimit: Int
    /// Sessions per week that count as "on track". Streaks use a weekly goal
    /// rather than a strict day chain so one missed day doesn't wipe progress.
    public let weeklySessionGoal: Int
    public let levels: [Level]

    public init(schemaVersion: Int, freeLevelLimit: Int, weeklySessionGoal: Int, levels: [Level]) {
        self.schemaVersion = schemaVersion
        self.freeLevelLimit = freeLevelLimit
        self.weeklySessionGoal = weeklySessionGoal
        self.levels = levels
    }

    public func level(id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    public func isFree(levelID: Int) -> Bool {
        levelID <= freeLevelLimit
    }
}
