import Testing
@testable import Core

@MainActor
struct WorkoutEngineTests {
    // prepare(5) -> contract(2, rep1) -> relax(2, rep1) -> contract(2, rep2) -> relax(2, rep2)
    private static let level = makeLevel(prepare: 5, contract: 2, hold: 0, relax: 2, reps: 2, sets: 1)
    private static let stepDurations = [5.0, 2.0, 2.0, 2.0, 2.0]

    private func makeEngine() -> (WorkoutEngine, TestClock) {
        let clock = TestClock()
        return (WorkoutEngine(level: Self.level, clock: clock, feedback: NoOpFeedback()), clock)
    }

    /// Runs the whole session to completion without waiting on real time.
    private func runToCompletion(_ engine: WorkoutEngine, _ clock: TestClock) {
        for duration in Self.stepDurations {
            clock.advance(by: duration)
            engine.tick()
        }
    }

    @Test func phaseAdvancesOnlyWhenClockCrossesStepDuration() {
        let (engine, clock) = makeEngine()
        engine.start()
        #expect(engine.currentPhase == .prepare)

        clock.advance(by: 4)
        engine.tick()
        #expect(engine.currentPhase == .prepare) // not yet at 5s

        clock.advance(by: 1)
        engine.tick()
        #expect(engine.currentPhase == .contract)
    }

    @Test func pauseDoesNotCountElapsedRealTime() {
        let (engine, clock) = makeEngine()
        engine.start()

        clock.advance(by: 1)
        engine.tick()
        #expect(engine.elapsedInStep == 1)

        engine.pause()
        clock.advance(by: 100) // time passes while paused — must not be counted
        engine.tick() // tick() is a no-op while paused
        #expect(engine.state == .paused)

        engine.resume()
        clock.advance(by: 1)
        engine.tick()

        #expect(engine.elapsedInStep == 2) // 1s before pause + 1s after resume, not 101s
        #expect(engine.currentPhase == .prepare) // still short of the 5s prepare duration
    }

    @Test func completingAllStepsEmitsACompletedRecord() throws {
        let (engine, clock) = makeEngine()
        var finished: SessionRecord?
        engine.onFinish = { finished = $0 }

        engine.start()
        runToCompletion(engine, clock)

        #expect(engine.state == .finished)
        let record = try #require(finished)
        #expect(record.wasCompleted)
        #expect(record.completedReps == Self.level.totalReps)
        #expect(record.plannedReps == Self.level.totalReps)
    }

    @Test func stoppingMidSessionRecordsPartialProgress() throws {
        let (engine, clock) = makeEngine()
        var interrupted: SessionRecord?
        engine.onFinish = { interrupted = $0 }

        engine.start()
        // Complete prepare + rep 1 (contract + relax), then stop mid rep 2.
        for duration in [5.0, 2.0, 2.0] {
            clock.advance(by: duration)
            engine.tick()
        }
        #expect(engine.currentPhase == .contract) // into rep 2

        engine.stop()

        let record = try #require(interrupted)
        #expect(!record.wasCompleted)
        #expect(record.completedReps == 1)
        #expect(record.plannedReps == Self.level.totalReps)
        #expect(engine.state == .idle)
    }

    @Test func skipStepAdvancesImmediatelyWithoutClock() {
        let (engine, _) = makeEngine()
        engine.start()
        #expect(engine.currentPhase == .prepare)

        engine.skipStep()
        #expect(engine.currentPhase == .contract)
    }

    // MARK: End-of-session state

    @Test func stoppingAnAlreadyFinishedSessionDoesNotRecordItTwice() {
        let (engine, clock) = makeEngine()
        var records: [SessionRecord] = []
        engine.onFinish = { records.append($0) }

        engine.start()
        runToCompletion(engine, clock)
        #expect(records.count == 1)

        engine.stop() // e.g. the user dismisses the summary screen

        #expect(records.count == 1)
        #expect(records.first?.wasCompleted == true)
    }

    @Test func currentPhaseIsFinishedOnceTheSessionEnds() {
        let (engine, clock) = makeEngine()
        engine.start()
        runToCompletion(engine, clock)

        #expect(engine.currentPhase == .finished)
        #expect(engine.remainingInStep == 0)
    }

    @Test func finishedSessionReportsFullProgressAndEveryRep() {
        let (engine, clock) = makeEngine()
        engine.start()
        runToCompletion(engine, clock)

        #expect(engine.overallProgress == 1)
        #expect(engine.completedReps == Self.level.totalReps)
    }

    @Test func startingAgainAfterFinishingResetsAndRecordsSeparately() {
        let (engine, clock) = makeEngine()
        var records: [SessionRecord] = []
        engine.onFinish = { records.append($0) }

        engine.start()
        runToCompletion(engine, clock)
        engine.start()
        #expect(engine.state == .running)
        #expect(engine.currentPhase == .prepare)
        runToCompletion(engine, clock)

        #expect(records.count == 2)
    }
}
