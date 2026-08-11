import Testing
@testable import Analytics

private final class RecordingTracker: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []
    func track(_ event: AnalyticsEvent) { events.append(event) }
}

struct AnalyticsTrackingTests {
    @Test func noOpTrackerAcceptsEventsWithoutCrashing() {
        let tracker = NoOpAnalyticsTracker()
        tracker.track(AnalyticsEvent(name: "session_started"))
    }

    @Test func eventCarriesNameAndParameters() {
        let tracker = RecordingTracker()
        tracker.track(AnalyticsEvent(name: "paywall_seen", parameters: ["source": "post_session"]))

        #expect(tracker.events.count == 1)
        #expect(tracker.events.first?.name == "paywall_seen")
        #expect(tracker.events.first?.parameters["source"] == "post_session")
    }
}
