/// Features that can sit behind the subscription.
///
/// Which of these are actually locked comes from `content.json`, never from
/// code — CLAUDE.md section 6 requires the free/paid boundary to be tunable
/// after launch without a release.
public enum PaidFeature: String, Codable, Sendable, CaseIterable {
    /// The near-black session screen for eyes-free use.
    case dimMode
    /// History, personal records and the weekly summary.
    case progress
}
