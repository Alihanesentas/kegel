import Core
import Testing
@testable import Feedback

@MainActor
struct FeedbackManagerTests {
    /// CoreHaptics behavior needs real hardware or a simulator to verify
    /// meaningfully — not available in this environment. This only checks
    /// the type is constructible and every call is a no-op safe path (no
    /// engine on this host) rather than a crash.
    @Test func allCallsAreSafeWithoutHapticHardware() {
        let manager = FeedbackManager()
        manager.prepare()
        for phase in Phase.allCases {
            manager.cue(for: phase, duration: 1)
        }
        manager.countdownTick()
    }

    @Test func vibrationCanBeToggledOffAndBackOnSafely() {
        let manager = FeedbackManager()
        manager.setVibrationEnabled(false)
        for phase in Phase.allCases {
            manager.cue(for: phase, duration: 1)
        }
        manager.countdownTick()

        manager.setVibrationEnabled(true)
        manager.cue(for: .contract, duration: 1)
    }
}
