import Foundation
import Testing
@testable import Core

struct ProgressionRuleTests {

    private let content = makeContent(levelCount: 4)

    @Test func firstLevelIsRecommendedWithNoHistory() {
        #expect(ProgressionRule.recommendedLevelID(from: [], in: content) == 1)
    }

    @Test func recommendsTheLevelAfterTheHighestCompletedOne() {
        let records = [
            makeRecord(date: date("2026-01-05T10:00:00Z"), levelID: 1),
            makeRecord(date: date("2026-01-06T10:00:00Z"), levelID: 3)
        ]
        #expect(ProgressionRule.recommendedLevelID(from: records, in: content) == 4)
    }

    @Test func abandonedSessionsDoNotUnlockTheNextLevel() {
        let records = [makeRecord(date: date("2026-01-05T10:00:00Z"), levelID: 2, wasCompleted: false)]
        #expect(ProgressionRule.recommendedLevelID(from: records, in: content) == 1)
    }

    @Test func recommendationStopsAtTheLastLevel() {
        let records = [makeRecord(date: date("2026-01-05T10:00:00Z"), levelID: 4)]
        #expect(ProgressionRule.recommendedLevelID(from: records, in: content) == 4)
    }

    @Test func advancedLevelsAreNotGatedByProgress() {
        // CLAUDE.md section 5: progression is training design, not a lock.
        // Only the subscription boundary restricts a level.
        #expect(content.isFree(levelID: 2))
        #expect(!content.isFree(levelID: 3))
    }
}

struct PersonalRecordsTests {

    @Test func emptyHistoryProducesZeroes() {
        let records = PersonalRecords(records: [])
        #expect(records == .empty)
    }

    @Test func aggregatesAcrossSessions() {
        let history = [
            makeRecord(date: date("2026-01-05T10:00:00Z"), levelID: 1, completedReps: 8, duration: 90),
            makeRecord(date: date("2026-01-06T10:00:00Z"), levelID: 3, completedReps: 20, duration: 240),
            makeRecord(
                date: date("2026-01-07T10:00:00Z"), levelID: 4,
                completedReps: 5, duration: 30, wasCompleted: false
            )
        ]

        let records = PersonalRecords(records: history)

        #expect(records.totalSessions == 3)
        #expect(records.completedSessions == 2)
        #expect(records.totalReps == 33)
        #expect(records.longestSession == 240)
        #expect(records.mostRepsInASession == 20)
        // Level 4 was abandoned, so level 3 is still the highest one finished.
        #expect(records.highestCompletedLevelID == 3)
    }
}

struct WeeklySummaryTests {

    // 2026-01-05 is a Monday; the week runs 05-11 Jan.
    private let now = date("2026-01-08T12:00:00Z")

    private func summary(_ records: [SessionRecord], goal: Int = 3) -> WeeklySummary {
        WeeklySummary(records: records, goal: goal, now: now, calendar: testCalendar)
    }

    @Test func countsOnlySessionsInTheCurrentWeek() {
        let result = summary([
            makeRecord(date: date("2026-01-05T08:00:00Z")),
            makeRecord(date: date("2026-01-07T08:00:00Z")),
            makeRecord(date: date("2026-01-02T08:00:00Z")) // previous week
        ])

        #expect(result.sessionsThisWeek == 2)
        #expect(!result.goalMet)
    }

    @Test func progressIsCappedAtOne() {
        let result = summary((0..<5).map { makeRecord(date: date("2026-01-0\(5 + $0)T08:00:00Z")) }, goal: 3)
        #expect(result.goalMet)
        #expect(result.progress == 1)
    }

    @Test func streakCountsConsecutiveWeeksThatMetTheGoal() {
        var history: [SessionRecord] = []
        // Three sessions in each of the two weeks before the current one.
        for day in ["2025-12-29", "2025-12-30", "2025-12-31"] { // week of Dec 29
            history.append(makeRecord(date: date("\(day)T08:00:00Z")))
        }
        for day in ["2026-01-01", "2026-01-02", "2026-01-03"] { // same week (Dec 29 - Jan 4)
            history.append(makeRecord(date: date("\(day)T08:00:00Z")))
        }

        #expect(summary(history).streakWeeks == 1)
    }

    @Test func anUnfinishedCurrentWeekDoesNotBreakTheStreak() {
        // Goal met last week, only one session so far this week. The streak
        // should still stand — this week just hasn't been earned yet.
        var history = ["2025-12-29", "2025-12-30", "2025-12-31"].map {
            makeRecord(date: date("\($0)T08:00:00Z"))
        }
        history.append(makeRecord(date: date("2026-01-05T08:00:00Z")))

        let result = summary(history)
        #expect(result.sessionsThisWeek == 1)
        #expect(!result.goalMet)
        #expect(result.streakWeeks == 1)
    }

    @Test func aMissedWeekEndsTheStreak() {
        // Goal met two weeks ago, nothing at all last week.
        let history = ["2025-12-22", "2025-12-23", "2025-12-24"].map {
            makeRecord(date: date("\($0)T08:00:00Z"))
        }
        #expect(summary(history).streakWeeks == 0)
    }

    @Test func currentWeekExtendsTheStreakOnceTheGoalIsMet() {
        var history = ["2025-12-29", "2025-12-30", "2025-12-31"].map {
            makeRecord(date: date("\($0)T08:00:00Z"))
        }
        history += ["2026-01-05", "2026-01-06", "2026-01-07"].map {
            makeRecord(date: date("\($0)T08:00:00Z"))
        }

        let result = summary(history)
        #expect(result.goalMet)
        #expect(result.streakWeeks == 2)
    }
}
