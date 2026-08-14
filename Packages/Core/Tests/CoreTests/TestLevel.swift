import Foundation
@testable import Core

/// Concise level builder for tests — keeps each test focused on the one or
/// two parameters it actually cares about.
func makeLevel(
    id: Int = 1,
    prepare: TimeInterval = 5,
    contract: TimeInterval = 2,
    hold: TimeInterval = 0,
    relax: TimeInterval = 2,
    reps: Int = 2,
    sets: Int = 1,
    restBetweenSets: TimeInterval = 0
) -> Level {
    Level(
        id: id,
        title: LocalizedText(["en": "Level \(id)"]),
        subtitle: LocalizedText(["en": "Subtitle"]),
        prepare: prepare,
        contract: contract,
        hold: hold,
        relax: relax,
        reps: reps,
        sets: sets,
        restBetweenSets: restBetweenSets
    )
}

func makeGuide() -> MuscleGuide {
    MuscleGuide(
        title: LocalizedText(["en": "Guide"]),
        intro: LocalizedText(["en": "Intro"]),
        steps: [MuscleGuide.Step(id: 1, title: LocalizedText(["en": "Step"]), body: LocalizedText(["en": "Body"]))],
        closing: LocalizedText(["en": "Closing"])
    )
}

func makeContent(
    schemaVersion: Int = 3,
    freeLevelLimit: Int = 2,
    weeklySessionGoal: Int = 5,
    levelCount: Int = 4,
    lockedFeatures: Set<PaidFeature> = []
) -> ContentSchema {
    ContentSchema(
        schemaVersion: schemaVersion,
        freeLevelLimit: freeLevelLimit,
        weeklySessionGoal: weeklySessionGoal,
        levels: (1 ... levelCount).map { makeLevel(id: $0) },
        muscleGuide: makeGuide(),
        lockedFeatures: lockedFeatures
    )
}

func makeRecord(
    date: Date,
    levelID: Int = 1,
    completedReps: Int = 10,
    plannedReps: Int = 10,
    duration: TimeInterval = 120,
    wasCompleted: Bool = true
) -> SessionRecord {
    SessionRecord(
        date: date,
        levelID: levelID,
        completedReps: completedReps,
        plannedReps: plannedReps,
        duration: duration,
        wasCompleted: wasCompleted
    )
}

/// Fixed calendar so week boundaries don't shift with the machine's locale.
var testCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    calendar.firstWeekday = 2 // Monday
    return calendar
}

func date(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter.date(from: iso) ?? Date(timeIntervalSince1970: 0)
}
