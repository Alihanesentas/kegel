import Analytics

/// The full set of events this app emits.
///
/// Keeping them in one list makes the privacy promise checkable at a glance:
/// every event is a bare behavioural signal with no parameters. No level IDs,
/// no rep counts, no dates, nothing derived from what the user's body did —
/// CLAUDE.md section 6.
extension AnalyticsEvent {
    static let onboardingCompleted = AnalyticsEvent(name: "onboarding_completed")
    static let sessionStarted = AnalyticsEvent(name: "session_started")
    static let sessionCompleted = AnalyticsEvent(name: "session_completed")
    static let sessionAbandoned = AnalyticsEvent(name: "session_abandoned")
    static let paywallSeen = AnalyticsEvent(name: "paywall_seen")
    static let paywallConverted = AnalyticsEvent(name: "paywall_converted")
}
