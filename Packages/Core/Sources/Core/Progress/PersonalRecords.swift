import Foundation

/// Personal bests derived from session history. CLAUDE.md / KICKOFF: a streak
/// counter alone doesn't motivate anyone — the user should be able to compare
/// against their own past.
///
/// These are plain aggregates of what the user did. Nothing here interprets
/// symptoms or infers anything about health (product constraint, section 1).
public struct PersonalRecords: Equatable, Sendable {
    public let totalSessions: Int
    public let completedSessions: Int
    public let totalReps: Int
    public let longestSession: TimeInterval
    public let mostRepsInASession: Int
    /// Highest level the user has finished end to end, if any.
    public let highestCompletedLevelID: Int?

    public init(
        totalSessions: Int,
        completedSessions: Int,
        totalReps: Int,
        longestSession: TimeInterval,
        mostRepsInASession: Int,
        highestCompletedLevelID: Int?
    ) {
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.totalReps = totalReps
        self.longestSession = longestSession
        self.mostRepsInASession = mostRepsInASession
        self.highestCompletedLevelID = highestCompletedLevelID
    }

    public static let empty = PersonalRecords(
        totalSessions: 0,
        completedSessions: 0,
        totalReps: 0,
        longestSession: 0,
        mostRepsInASession: 0,
        highestCompletedLevelID: nil
    )

    public init(records: [SessionRecord]) {
        totalSessions = records.count
        completedSessions = records.filter(\.wasCompleted).count
        totalReps = records.reduce(0) { $0 + $1.completedReps }
        longestSession = records.map(\.duration).max() ?? 0
        mostRepsInASession = records.map(\.completedReps).max() ?? 0
        highestCompletedLevelID = records.filter(\.wasCompleted).map(\.levelID).max()
    }
}
