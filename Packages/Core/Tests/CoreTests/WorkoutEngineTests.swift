import Testing
@testable import Core

@MainActor
struct WorkoutEngineTests {

    // prepare(5) -> contract(2, rep1) -> relax(2, rep1) -> contract(2, rep2) -> relax(2, rep2)
    private static let testLevel = Level(
        id: 1, title: "T", subtitle: "S",
        contract: 2, hold: 0, relax: 2,
        reps: 2, sets: 1, restBetweenSets: 0
    )

    private func makeEngine() -> (WorkoutEngine, TestClock) {
        let clock = TestClock()
        let engine = WorkoutEngine(level: Self.testLevel, clock: clock, feedback: NoOpFeedback())
        return (engine, clock)
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
        for duration in [5.0, 2.0, 2.0, 2.0, 2.0] {
            clock.advance(by: duration)
            engine.tick()
        }

        #expect(engine.state == .finished)
        let record = try #require(finished)
        #expect(record.wasCompleted)
        #expect(record.completedReps == Self.testLevel.totalReps)
        #expect(record.plannedReps == Self.testLevel.totalReps)
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
        #expect(record.plannedReps == Self.testLevel.totalReps)
        #expect(engine.state == .idle)
    }

    @Test func skipStepAdvancesImmediatelyWithoutClock() {
        let (engine, _) = makeEngine()
        engine.start()
        #expect(engine.currentPhase == .prepare)

        engine.skipStep()
        #expect(engine.currentPhase == .contract)
    }
}
