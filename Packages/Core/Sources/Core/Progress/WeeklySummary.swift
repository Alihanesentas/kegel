import Foundation

/// How the current week is going, plus how many weeks in a row the user has
/// hit their goal.
///
/// The streak is deliberately weekly, not a day chain (KICKOFF_PROMPT M2): a
/// strict daily streak punishes one missed day by resetting everything, which
/// makes people quit. A week still in progress never breaks the streak — it
/// simply hasn't been earned yet.
public struct WeeklySummary: Equatable, Sendable {
    public let sessionsThisWeek: Int
    public let goal: Int
    /// Consecutive *completed* weeks that met the goal, most recent first.
    public let streakWeeks: Int

    public init(sessionsThisWeek: Int, goal: Int, streakWeeks: Int) {
        self.sessionsThisWeek = sessionsThisWeek
        self.goal = goal
        self.streakWeeks = streakWeeks
    }

    public var goalMet: Bool {
        sessionsThisWeek >= goal
    }

    /// 0-1, capped — for a progress bar.
    public var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(sessionsThisWeek) / Double(goal))
    }

    /// Builds the summary from history.
    ///
    /// `calendar` is injected so tests can pin the week-start rule and time
    /// zone instead of depending on the machine's locale.
    public init(
        records: [SessionRecord],
        goal: Int,
        now: Date,
        calendar: Calendar = .current
    ) {
        self.goal = goal

        let countsByWeek = Dictionary(grouping: records) { record in
            calendar.startOfWeek(for: record.date)
        }.mapValues(\.count)

        let currentWeek = calendar.startOfWeek(for: now)
        sessionsThisWeek = countsByWeek[currentWeek] ?? 0

        var streak = 0
        // The in-progress week only extends the streak once it's been earned;
        // if it hasn't, keep walking back rather than treating it as a break.
        if (countsByWeek[currentWeek] ?? 0) >= goal {
            streak += 1
        }
        var week = currentWeek
        while let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: week) {
            guard (countsByWeek[previous] ?? 0) >= goal else { break }
            streak += 1
            week = previous
        }
        streakWeeks = streak
    }
}

extension Calendar {
    /// Midnight on the first day of the week containing `date`.
    func startOfWeek(for date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }
}
