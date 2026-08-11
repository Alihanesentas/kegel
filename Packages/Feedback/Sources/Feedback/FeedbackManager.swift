import AVFoundation
import Core
import CoreHaptics
import Foundation

/// Concrete `FeedbackEmitting`. The only place in the app that talks to
/// CoreHaptics / AVSpeechSynthesizer / AVAudioSession directly — `Core` and
/// everything above `Feedback` only ever see the protocol.
public final class FeedbackManager: FeedbackEmitting, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var hapticEngine: CHHapticEngine?

    public init() {
        configureAudioSession()
        prepareHapticEngine()
    }

    public func prepare() {
        try? hapticEngine?.start()
    }

    public func cue(for phase: Phase, duration: Double) {
        playHaptic(for: phase)
        speak(phase.localizationKey)
    }

    public func countdownTick() {
        playTransientHaptic(intensity: 0.6, sharpness: 0.4)
    }

    // MARK: Audio session

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // Never take over the user's music — mix in and duck instead of interrupting.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true)
        #endif
    }

    // MARK: Haptics

    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
    }

    private func playHaptic(for phase: Phase) {
        switch phase {
        case .contract:
            playTransientHaptic(intensity: 1.0, sharpness: 0.8)
        case .hold:
            playContinuousHaptic(intensity: 0.5, sharpness: 0.3, duration: 0.3)
        case .relax:
            playTransientHaptic(intensity: 0.4, sharpness: 0.2)
        case .prepare, .rest, .finished:
            break
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
        guard let hapticEngine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? hapticEngine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    // MARK: Speech

    private func speak(_ localizationKey: String) {
        let text = String(localized: String.LocalizationValue(localizationKey), bundle: .module)
        let utterance = AVSpeechUtterance(string: text)
        synthesizer.speak(utterance)
    }
}
