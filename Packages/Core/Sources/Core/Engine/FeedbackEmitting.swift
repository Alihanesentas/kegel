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
}

public struct NoOpFeedback: FeedbackEmitting {
    public init() {}
    public func prepare() {}
    public func cue(for phase: Phase, duration: Double) {}
    public func countdownTick() {}
}
