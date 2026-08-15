import Core
import CoreHaptics
import Foundation

/// Concrete `FeedbackEmitting`. The only place in the app that talks to
/// CoreHaptics directly — `Core` and everything above `Feedback` only ever
/// see the protocol.
///
/// Sessions are silent by design: no spoken phase names, no audio cues.
/// Every phase change and countdown tick is a distinct haptic pattern
/// instead, toggleable in Settings via ``setVibrationEnabled(_:)``.
@MainActor
public final class FeedbackManager: FeedbackEmitting {
    private var hapticEngine: CHHapticEngine?
    private var isVibrationEnabled = true

    public init() {
        prepareHapticEngine()
    }

    public func prepare() {
        try? hapticEngine?.start()
    }

    public func cue(for phase: Phase, duration _: Double) {
        playHaptic(for: phase)
    }

    public func countdownTick() {
        playTransientHaptic(intensity: 0.6, sharpness: 0.4)
    }

    public func setVibrationEnabled(_ enabled: Bool) {
        isVibrationEnabled = enabled
    }

    // MARK: Haptics

    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
    }

    /// Every phase gets its own pattern so the user can tell them apart by
    /// feel alone — this is the only feedback a session gives now.
    private func playHaptic(for phase: Phase) {
        switch phase {
        case .prepare:
            playTransientHaptic(intensity: 0.3, sharpness: 0.2)
        case .contract:
            playTransientHaptic(intensity: 1.0, sharpness: 0.8)
        case .hold:
            playContinuousHaptic(intensity: 0.5, sharpness: 0.3, duration: 0.3)
        case .relax:
            playTransientHaptic(intensity: 0.4, sharpness: 0.2)
        case .rest:
            playTransientHaptic(intensity: 0.3, sharpness: 0.1)
        case .finished:
            playContinuousHaptic(intensity: 0.8, sharpness: 0.5, duration: 0.5)
        }
    }

    private func playTransientHaptic(intensity: Float, sharpness: Float) {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        play(events: [event])
    }

    private func playContinuousHaptic(intensity: Float, sharpness: Float, duration: TimeInterval) {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )
        play(events: [event])
    }

    private func play(events: [CHHapticEvent]) {
        guard isVibrationEnabled,
              let hapticEngine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? hapticEngine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
