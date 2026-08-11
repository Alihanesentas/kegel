import Foundation

/// One executable step of a session. `WorkoutEngine` only ever walks a flat
/// array of these — `Level.buildSteps()` is the sole place that expands a
/// level's parameters into this list.
public struct WorkoutStep: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let phase: Phase
    public let duration: TimeInterval
    public let repIndex: Int?
    public let setIndex: Int?

    public init(
        id: UUID = UUID(),
        phase: Phase,
        duration: TimeInterval,
        repIndex: Int?,
        setIndex: Int?
    ) {
        self.id = id
        self.phase = phase
        self.duration = duration
        self.repIndex = repIndex
        self.setIndex = setIndex
    }
}
