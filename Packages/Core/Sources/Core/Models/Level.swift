import Foundation

/// Level parameters. These come from `content.json` (see `Program/ContentLoader.swift`) —
/// never hardcoded in Swift, so free/paid limits and durations can be tuned without a release.
public struct Level: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let contract: TimeInterval
    public let hold: TimeInterval // 0 skips the "hold" phase
    public let relax: TimeInterval
    public let reps: Int
    public let sets: Int
    public let restBetweenSets: TimeInterval

    public var prepare: TimeInterval { 5 }

    public var totalDuration: TimeInterval {
        let perRep = contract + hold + relax
        let work = perRep * Double(reps) * Double(sets)
        let rest = restBetweenSets * Double(max(0, sets - 1))
        return prepare + work + rest
    }

    public var totalReps: Int { reps * sets }

    public init(
        id: Int,
        title: String,
        subtitle: String,
        contract: TimeInterval,
        hold: TimeInterval,
        relax: TimeInterval,
        reps: Int,
        sets: Int,
        restBetweenSets: TimeInterval
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.contract = contract
        self.hold = hold
        self.relax = relax
        self.reps = reps
        self.sets = sets
        self.restBetweenSets = restBetweenSets
    }

    /// Expands the level into a flat step list. The engine only ever executes this list.
    public func buildSteps() -> [WorkoutStep] {
        var steps: [WorkoutStep] = [
            WorkoutStep(phase: .prepare, duration: prepare, repIndex: nil, setIndex: nil)
        ]

        for set in 1...sets {
            for rep in 1...reps {
                steps.append(WorkoutStep(phase: .contract, duration: contract, repIndex: rep, setIndex: set))
                if hold > 0 {
                    steps.append(WorkoutStep(phase: .hold, duration: hold, repIndex: rep, setIndex: set))
                }
                steps.append(WorkoutStep(phase: .relax, duration: relax, repIndex: rep, setIndex: set))
            }
            if set < sets {
                steps.append(WorkoutStep(phase: .rest, duration: restBetweenSets, repIndex: nil, setIndex: set))
            }
        }
        return steps
    }
}
