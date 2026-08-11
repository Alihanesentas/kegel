import Core
import Foundation
import Observation
import Persistence

/// In-memory view of session history, backed by a `Repository`.
///
/// Records never leave the device (CLAUDE.md section 6) — this is the only
/// place the app holds them, and nothing here talks to a network.
@MainActor
@Observable
public final class SessionStore {
    public private(set) var records: [SessionRecord] = []
    public private(set) var isLoaded = false

    private let repository: any Repository<SessionRecord>

    public init(repository: any Repository<SessionRecord>) {
        self.repository = repository
    }

    public func load() async {
        records = (try? await repository.loadAll()) ?? []
        isLoaded = true
    }

    /// Appends a finished session and persists. A write failure is not
    /// surfaced to the user — losing one record is not worth interrupting
    /// them over, and the in-memory list stays correct for this launch.
    public func add(_ record: SessionRecord) async {
        records.append(record)
        try? await repository.save(records)
    }

    public var personalRecords: PersonalRecords {
        PersonalRecords(records: records)
    }

    public func weeklySummary(goal: Int, now: Date = Date()) -> WeeklySummary {
        WeeklySummary(records: records, goal: goal, now: now)
    }

    public func recommendedLevelID(in content: ContentSchema) -> Int {
        ProgressionRule.recommendedLevelID(from: records, in: content)
    }

    public var hasCompletedASession: Bool {
        records.contains(where: \.wasCompleted)
    }
}
