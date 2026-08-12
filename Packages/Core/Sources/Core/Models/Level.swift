import Foundation

/// Level parameters. Every value here comes from `content.json` (see
/// `Program/ContentLoader.swift`) — nothing is hardcoded in Swift, so
/// durations, rep counts and the free/paid boundary can be tuned without
/// shipping a release. CLAUDE.md section 5.
public struct Level: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let title: LocalizedText
    public let subtitle: LocalizedText
    /// Lead-in before the first rep. Content-driven like everything else.
    public let prepare: TimeInterval
    public let contract: TimeInterval
    public let hold: TimeInterval // 0 skips the "hold" phase
    public let relax: TimeInterval
    public let reps: Int
    public let sets: Int
    public let restBetweenSets: TimeInterval

    public var totalDuration: TimeInterval {
        let perRep = contract + hold + relax
        let work = perRep * Double(reps) * Double(sets)
        let rest = restBetweenSets * Double(max(0, sets - 1))
        return prepare + work + rest
    }

    public var totalReps: Int {
        reps * sets
    }

    public init(
        id: Int,
        title: LocalizedText,
        subtitle: LocalizedText,
        prepare: TimeInterval,
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
        self.prepare = prepare
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
            WorkoutStep(phase: .prepare, duration: prepare, repIndex: nil, setIndex: nil),
        ]

        for set in 1 ... sets {
            for rep in 1 ... reps {
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
