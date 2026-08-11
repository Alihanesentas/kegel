import Foundation

/// Versioned shape of `content.json`. Level parameters, copy and the
/// free/paid boundary all live here rather than in Swift — see CLAUDE.md
/// section 5 and section 6 ("Ücretsiz/ücretli sınırı content.json'dan gelir").
public struct ContentSchema: Codable, Sendable {
    public let schemaVersion: Int
    /// Levels with `id` at or below this are free; the rest need a subscription.
    public let freeLevelLimit: Int
    /// Sessions per week that count as "on track". Streaks use a weekly goal
    /// rather than a strict day chain so one missed day doesn't wipe progress.
    public let weeklySessionGoal: Int
    public let levels: [Level]
    public let muscleGuide: MuscleGuide

    /// Features gated behind the subscription. Decoded leniently: a value this
    /// build doesn't recognise is ignored rather than failing the whole
    /// document, so a newer `content.json` can name a feature that only ships
    /// in a later app version.
    public let lockedFeatures: Set<PaidFeature>

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, freeLevelLimit, weeklySessionGoal, levels, muscleGuide, lockedFeatures
    }

    public init(
        schemaVersion: Int,
        freeLevelLimit: Int,
        weeklySessionGoal: Int,
        levels: [Level],
        muscleGuide: MuscleGuide,
        lockedFeatures: Set<PaidFeature> = []
    ) {
        self.schemaVersion = schemaVersion
        self.freeLevelLimit = freeLevelLimit
        self.weeklySessionGoal = weeklySessionGoal
        self.levels = levels
        self.muscleGuide = muscleGuide
        self.lockedFeatures = lockedFeatures
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        freeLevelLimit = try container.decode(Int.self, forKey: .freeLevelLimit)
        weeklySessionGoal = try container.decode(Int.self, forKey: .weeklySessionGoal)
        levels = try container.decode([Level].self, forKey: .levels)
        muscleGuide = try container.decode(MuscleGuide.self, forKey: .muscleGuide)

        let rawFeatures = try container.decodeIfPresent([String].self, forKey: .lockedFeatures) ?? []
        lockedFeatures = Set(rawFeatures.compactMap(PaidFeature.init(rawValue:)))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(freeLevelLimit, forKey: .freeLevelLimit)
        try container.encode(weeklySessionGoal, forKey: .weeklySessionGoal)
        try container.encode(levels, forKey: .levels)
        try container.encode(muscleGuide, forKey: .muscleGuide)
        try container.encode(lockedFeatures.map(\.rawValue).sorted(), forKey: .lockedFeatures)
    }

    public func level(id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    public func isFree(levelID: Int) -> Bool {
        levelID <= freeLevelLimit
    }

    public func requiresSubscription(_ feature: PaidFeature) -> Bool {
        lockedFeatures.contains(feature)
    }
}
