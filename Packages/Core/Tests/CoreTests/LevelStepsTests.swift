import Testing
@testable import Core

struct LevelStepsTests {

    @Test func stepCountMatchesRepsAndSets() {
        let level = Level(id: 1, title: "T", subtitle: "S", contract: 3, hold: 2, relax: 4, reps: 2, sets: 2, restBetweenSets: 10)
        let steps = level.buildSteps()

        // prepare + (contract, hold, relax) x reps x sets + rest between sets
        let expectedCount = 1 + (3 * 2 * 2) + 1
        #expect(steps.count == expectedCount)
        #expect(steps.first?.phase == .prepare)
        #expect(steps.filter { $0.phase == .rest }.count == 1)
    }

    @Test func holdPhaseIsSkippedWhenZero() {
        let level = Level(id: 1, title: "T", subtitle: "S", contract: 3, hold: 0, relax: 4, reps: 3, sets: 1, restBetweenSets: 0)
        let steps = level.buildSteps()

        #expect(steps.filter { $0.phase == .hold }.isEmpty)
        // prepare + (contract, relax) x 3 reps, no rest (single set)
        #expect(steps.count == 1 + (2 * 3))
    }

    @Test func repAndSetIndicesAreOneBased() {
        let level = Level(id: 1, title: "T", subtitle: "S", contract: 1, hold: 0, relax: 1, reps: 2, sets: 2, restBetweenSets: 5)
        let steps = level.buildSteps()

        let firstRepSteps = steps.filter { $0.repIndex == 1 && $0.setIndex == 1 }
        #expect(!firstRepSteps.isEmpty)
        #expect(steps.contains { $0.repIndex == 2 && $0.setIndex == 2 })
        #expect(!steps.contains { $0.repIndex == 0 || $0.setIndex == 0 })
    }

    @Test func totalRepsMultipliesRepsBySets() {
        let level = Level(id: 1, title: "T", subtitle: "S", contract: 1, hold: 0, relax: 1, reps: 10, sets: 3, restBetweenSets: 5)
        #expect(level.totalReps == 30)
    }
}
