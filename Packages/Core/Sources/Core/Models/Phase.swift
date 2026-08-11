/// A single stage of a workout step. Pure domain data — no display text lives
/// here; display and spoken strings are resolved from `localizationKey` by the
/// layers that own localization (App / Feedback), each via its own String Catalog.
public enum Phase: String, Codable, CaseIterable, Sendable {
    case prepare
    case contract
    case hold
    case relax
    case rest
    case finished

    /// Stable, non-localized key used to look up display/spoken text. Not user-facing text itself.
    public var localizationKey: String {
        "phase.\(rawValue)"
    }
}
