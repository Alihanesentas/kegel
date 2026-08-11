import Testing
@testable import Core

struct LevelStepsTests {

    @Test func stepCountMatchesRepsAndSets() {
        let steps = makeLevel(hold: 2, reps: 2, sets: 2, restBetweenSets: 10).buildSteps()

        // prepare + (contract, hold, relax) x reps x sets + rest between sets
        #expect(steps.count == 1 + (3 * 2 * 2) + 1)
        #expect(steps.first?.phase == .prepare)
        #expect(steps.filter { $0.phase == .rest }.count == 1)
    }

    @Test func holdPhaseIsSkippedWhenZero() {
        let steps = makeLevel(hold: 0, reps: 3, sets: 1).buildSteps()

        #expect(steps.filter { $0.phase == .hold }.isEmpty)
        #expect(steps.count == 1 + (2 * 3))
    }

    @Test func repAndSetIndicesAreOneBased() {
        let steps = makeLevel(reps: 2, sets: 2, restBetweenSets: 5).buildSteps()

        #expect(steps.contains { $0.repIndex == 1 && $0.setIndex == 1 })
        #expect(steps.contains { $0.repIndex == 2 && $0.setIndex == 2 })
        #expect(!steps.contains { $0.repIndex == 0 || $0.setIndex == 0 })
    }

    @Test func totalRepsMultipliesRepsBySets() {
        #expect(makeLevel(reps: 10, sets: 3).totalReps == 30)
    }

    @Test func prepareDurationComesFromTheLevelNotAConstant() {
        let level = makeLevel(prepare: 9)
        #expect(level.buildSteps().first?.duration == 9)
    }

    @Test func totalDurationCountsWorkAndRestButNotATrailingRest() {
        let level = makeLevel(prepare: 5, contract: 2, hold: 1, relax: 2, reps: 2, sets: 2, restBetweenSets: 10)
        // 5 prepare + (2+1+2) x 2 reps x 2 sets + 10 rest once between the two sets
        #expect(level.totalDuration == 5 + 20 + 10)
    }
}
