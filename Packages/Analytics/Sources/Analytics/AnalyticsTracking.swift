/// Behavior events only — screen views, session started/finished, paywall
/// seen/converted. Never exercise content, level history, or personal data:
/// CLAUDE.md section 6, "Sağlık verisi asla sunucuya gitmez."
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Placeholder until a real analytics SDK is wired in behind this protocol — M5 work.
public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}
    public func track(_: AnalyticsEvent) {}
}
