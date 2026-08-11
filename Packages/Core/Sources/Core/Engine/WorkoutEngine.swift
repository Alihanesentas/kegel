import Foundation
import Observation

/// The state machine that drives a session.
///
/// Elapsed time is computed from the injected `Clock`'s `now()` minus the
/// current step's start time, never by counting ticks — timers drift and skip
/// ticks under load, so a 10-minute session would otherwise lose seconds.
///
/// `Core` doesn't run its own background timer: `tick()` is public and does
/// the recompute-and-advance work, but something outside `Core` (the
/// `SessionDriver` in `Features`) is responsible for calling it repeatedly in
/// production. Tests call `tick()` directly after moving a `TestClock`
/// forward — no real waiting, no `Timer`.
@MainActor
@Observable
public final class WorkoutEngine {

    public enum State: Equatable, Sendable {
        case idle
        case running
        case paused
        case finished
    }

    public private(set) var state: State = .idle
    public private(set) var steps: [WorkoutStep]
    public private(set) var stepIndex: Int = 0
    public private(set) var elapsedInStep: TimeInterval = 0
    public private(set) var level: Level

    private var stepStartedAt: Date?
    private var carriedElapsed: TimeInterval = 0
    private var sessionStartedAt: Date?
    private var lastSpokenSecond: Int = -1
    /// Guards against emitting two records for one session — without it,
    /// calling `stop()` on an already-finished engine would log a second,
    /// "incomplete" record for a session the user actually completed.
    private var hasEmittedRecord = false

    private let clock: Clock
    private let feedback: FeedbackEmitting
    public var onFinish: ((SessionRecord) -> Void)?

    public init(level: Level, clock: Clock = SystemClock(), feedback: FeedbackEmitting = NoOpFeedback()) {
        self.level = level
        self.steps = level.buildSteps()
        self.clock = clock
        self.feedback = feedback
    }

    // MARK: Derived state

    public var currentStep: WorkoutStep? {
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    /// The phase to show. Once the session ends this reports `.finished`
    /// rather than whatever the last executed step happened to be.
    public var currentPhase: Phase {
        guard state != .finished else { return .finished }
        return currentStep?.phase ?? .finished
    }

    public var remainingInStep: TimeInterval {
        guard state != .finished, let step = currentStep else { return 0 }
        return max(0, step.duration - elapsedInStep)
    }

    /// 0-1 progress within the current step. Drives the breathing ring.
    public var stepProgress: Double {
        guard state != .finished else { return 1 }
        guard let step = currentStep, step.duration > 0 else { return 0 }
        return min(1, elapsedInStep / step.duration)
    }

    public var overallProgress: Double {
        guard state != .finished else { return 1 }
        let total = steps.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return 0 }
        let done = steps.prefix(stepIndex).reduce(0) { $0 + $1.duration } + elapsedInStep
        return min(1, done / total)
    }

    /// Number of completed "relax" phases = number of completed reps. On a
    /// finished session every step counts; mid-session only the steps already
    /// left behind do.
    public var completedReps: Int {
        let completedSteps = state == .finished ? steps[...] : steps.prefix(stepIndex)
        return completedSteps.filter { $0.phase == .relax }.count
    }

    public var currentSet: Int { currentStep?.setIndex ?? 1 }
    public var currentRep: Int { currentStep?.repIndex ?? 0 }

    // MARK: Control

    public func load(level: Level) {
        stop(record: false)
        self.level = level
        self.steps = level.buildSteps()
    }

    public func start() {
        guard state == .idle || state == .finished else { return }
        if steps.isEmpty { steps = level.buildSteps() }
        stepIndex = 0
        elapsedInStep = 0
        carriedElapsed = 0
        hasEmittedRecord = false
        sessionStartedAt = clock.now()
        state = .running
        feedback.prepare()
        beginCurrentStep()
    }

    public func pause() {
        guard state == .running else { return }
        carriedElapsed = elapsedInStep
        stepStartedAt = nil
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        stepStartedAt = clock.now()
        state = .running
    }

    public func togglePause() {
        state == .running ? pause() : resume()
    }

    /// Ends the session and returns the engine to `.idle`. A session that
    /// already finished on its own is not recorded again.
    public func stop(record: Bool = true) {
        if record, !hasEmittedRecord, sessionStartedAt != nil, state != .idle {
            emitRecord(completed: false)
        }
        stepStartedAt = nil
        carriedElapsed = 0
        sessionStartedAt = nil
        elapsedInStep = 0
        stepIndex = 0
        hasEmittedRecord = false
        state = .idle
    }

    /// User chooses to skip the current rep/step.
    public func skipStep() {
        guard state == .running || state == .paused else { return }
        advance()
    }

    /// Recomputes elapsed time from the clock and advances phases as needed.
    /// Call this repeatedly (production: `SessionDriver`; tests: directly).
    public func tick() {
        guard state == .running, let start = stepStartedAt, let step = currentStep else { return }
        elapsedInStep = carriedElapsed + clock.now().timeIntervalSince(start)

        // Countdown tick for the last 3 seconds — the user shouldn't need to look at the screen.
        let remaining = Int(ceil(step.duration - elapsedInStep))
        if remaining <= 3, remaining > 0, remaining != lastSpokenSecond {
            lastSpokenSecond = remaining
            feedback.countdownTick()
        }

        if elapsedInStep >= step.duration {
            advance()
        }
    }

    // MARK: Private

    private func beginCurrentStep() {
        stepStartedAt = clock.now()
        carriedElapsed = 0
        elapsedInStep = 0
        lastSpokenSecond = -1
        if let step = currentStep {
            feedback.cue(for: step.phase, duration: step.duration)
        }
    }

    private func advance() {
        let next = stepIndex + 1
        if next >= steps.count {
            finish()
        } else {
            stepIndex = next
            beginCurrentStep()
        }
    }

    private func finish() {
        state = .finished
        feedback.cue(for: .finished, duration: 0)
        emitRecord(completed: true)
        stepStartedAt = nil
    }

    private func emitRecord(completed: Bool) {
        hasEmittedRecord = true
        let duration = sessionStartedAt.map { clock.now().timeIntervalSince($0) } ?? 0
        let record = SessionRecord(
            date: clock.now(),
            levelID: level.id,
            completedReps: completed ? level.totalReps : completedReps,
            plannedReps: level.totalReps,
            duration: duration,
            wasCompleted: completed
        )
        onFinish?(record)
    }
}
