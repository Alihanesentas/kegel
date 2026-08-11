import Foundation

/// A completed or interrupted session. Stored on-device only (see CLAUDE.md
/// section 6 — health data never leaves the device) via a `Repository` in the
/// `Persistence` package.
public struct SessionRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let levelID: Int
    public let completedReps: Int
    public let plannedReps: Int
    public let duration: TimeInterval
    public let wasCompleted: Bool

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        levelID: Int,
        completedReps: Int,
        plannedReps: Int,
        duration: TimeInterval,
        wasCompleted: Bool
    ) {
        self.id = id
        self.date = date
        self.levelID = levelID
        self.completedReps = completedReps
        self.plannedReps = plannedReps
        self.duration = duration
        self.wasCompleted = wasCompleted
    }
}
