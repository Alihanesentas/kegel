import Core
import Foundation
import Observation

/// Drives `WorkoutEngine.tick()`.
///
/// `Core` deliberately owns no timer (it must not import a platform framework
/// and must stay testable without real time), so the repeated nudging lives
/// here. The engine still computes elapsed time from its `Clock`, so a late or
/// skipped tick costs accuracy in *display* only — never in phase timing.
@MainActor
@Observable
public final class SessionDriver {
    /// ~30 Hz: smooth enough for the breathing ring without waking the CPU needlessly.
    private static let tickInterval = Duration.milliseconds(33)

    public let engine: WorkoutEngine
    private var loop: Task<Void, Never>?

    public init(engine: WorkoutEngine) {
        self.engine = engine
    }

    public func start() {
        engine.start()
        startLoop()
    }

    public func pause() {
        engine.pause()
    }

    public func resume() {
        engine.resume()
        startLoop()
    }

    public func togglePause() {
        engine.state == .running ? pause() : resume()
    }

    public func skip() {
        engine.skipStep()
    }

    public func stop(record: Bool = true) {
        loop?.cancel()
        loop = nil
        engine.stop(record: record)
    }

    private func startLoop() {
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.tickInterval)
                guard let self else { return }
                guard engine.state == .running else {
                    // Paused or finished: stop burning ticks. `resume()`
                    // starts a fresh loop.
                    return
                }
                engine.tick()
            }
        }
    }
}
