/// Haptic/audio output, injected so `Core` never imports a platform framework.
/// The `Feedback` package provides the real implementation (CoreHaptics +
/// AVSpeechSynthesizer); tests and previews use `NoOpFeedback`.
public protocol FeedbackEmitting: Sendable {
    /// Called once when a session starts, before the first step begins.
    func prepare()
    /// Called at the start of every step.
    func cue(for phase: Phase, duration: Double)
    /// Called on each of the last 3 whole seconds of a step.
    func countdownTick()
    /// Turns haptic feedback on or off. The session is silent (no speech,
    /// no audio) either way — this only controls the vibration cues fired
    /// by ``cue(for:duration:)`` and ``countdownTick()``.
    func setVibrationEnabled(_ enabled: Bool)
}

public struct NoOpFeedback: FeedbackEmitting {
    public init() {}
    public func prepare() {}
    public func cue(for _: Phase, duration _: Double) {}
    public func countdownTick() {}
    public func setVibrationEnabled(_: Bool) {}
}
