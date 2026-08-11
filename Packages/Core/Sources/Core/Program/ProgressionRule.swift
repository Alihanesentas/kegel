import Foundation

/// Decides which level to suggest next.
///
/// Deliberately advisory, not a gate. CLAUDE.md section 5: the first level is
/// training design, "bir güvenlik kapısı değil" — the user may jump straight
/// to an advanced level if they want. The only thing that actually restricts a
/// level is the subscription boundary (`ContentSchema.isFree(levelID:)`).
public enum ProgressionRule {

    /// One past the highest level the user has *completed*, clamped to the
    /// catalogue. With no history at all this is the first level.
    public static func recommendedLevelID(from records: [SessionRecord], in content: ContentSchema) -> Int {
        let ids = content.levels.map(\.id).sorted()
        guard let firstID = ids.first, let lastID = ids.last else { return 1 }

        let highestCompleted = records
            .filter(\.wasCompleted)
            .map(\.levelID)
            .max()

        guard let highestCompleted else { return firstID }

        let next = ids.first { $0 > highestCompleted }
        return next ?? lastID
    }
}
