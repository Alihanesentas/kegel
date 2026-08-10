import Foundation
import Combine
import UIKit

/// Antrenmanı yürüten durum makinesi.
///
/// Önemli tasarım kararı: geçen süre `Timer` tick'leri sayılarak DEĞİL, her adımın
/// başlangıç tarihinden itibaren `Date()` farkı alınarak hesaplanır. Timer'lar
/// kayar (drift), sistem yükü altında tick atlar ve arka planda tamamen durur —
/// tick sayarsan 10 dakikalık seansta saniyeler kaybolur.
@MainActor
final class WorkoutEngine: ObservableObject {

    enum State: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    // MARK: Yayınlanan durum

    @Published private(set) var state: State = .idle
    @Published private(set) var steps: [WorkoutStep] = []
    @Published private(set) var stepIndex: Int = 0
    @Published private(set) var elapsedInStep: TimeInterval = 0

    private(set) var level: Level = Level.catalog[0]

    // MARK: Dahili

    private var timer: AnyCancellable?
    private var stepStartedAt: Date?
    private var carriedElapsed: TimeInterval = 0   // duraklatmadan devralınan süre
    private var sessionStartedAt: Date?
    private var lastSpokenSecond: Int = -1

    private let feedback: FeedbackManager
    var onFinish: ((SessionRecord) -> Void)?

    init(feedback: FeedbackManager = .shared) {
        self.feedback = feedback
    }

    // MARK: Türetilmiş değerler

    var currentStep: WorkoutStep? {
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    var currentPhase: Phase { currentStep?.phase ?? .finished }

    var remainingInStep: TimeInterval {
        guard let step = currentStep else { return 0 }
        return max(0, step.duration - elapsedInStep)
    }

    /// Mevcut adımın 0–1 arası ilerlemesi. Nefes halkası bunu kullanıyor.
    var stepProgress: Double {
        guard let step = currentStep, step.duration > 0 else { return 0 }
        return min(1, elapsedInStep / step.duration)
    }

    var overallProgress: Double {
        let total = steps.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return 0 }
        let done = steps.prefix(stepIndex).reduce(0) { $0 + $1.duration } + elapsedInStep
        return min(1, done / total)
    }

    var completedReps: Int {
        // Tamamlanan "bırak" fazlarının sayısı = tamamlanan tekrar sayısı.
        steps.prefix(stepIndex).filter { $0.phase == .relax }.count
    }

    var currentSet: Int { currentStep?.setIndex ?? 1 }
    var currentRep: Int { currentStep?.repIndex ?? 0 }

    // MARK: Kontrol

    func load(level: Level) {
        stop(record: false)
        self.level = level
        self.steps = level.buildSteps()
        self.stepIndex = 0
        self.elapsedInStep = 0
        self.state = .idle
    }

    func start() {
        guard state == .idle || state == .finished else { return }
        if steps.isEmpty { steps = level.buildSteps() }
        stepIndex = 0
        elapsedInStep = 0
        carriedElapsed = 0
        sessionStartedAt = Date()
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        feedback.prepare()
        beginCurrentStep()
        startTicking()
    }

    func pause() {
        guard state == .running else { return }
        carriedElapsed = elapsedInStep
        stepStartedAt = nil
        timer?.cancel()
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resume() {
        guard state == .paused else { return }
        stepStartedAt = Date()
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        startTicking()
    }

    func togglePause() {
        state == .running ? pause() : resume()
    }

    func stop(record: Bool = true) {
        timer?.cancel()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        if record, sessionStartedAt != nil, state != .idle {
            emitRecord(completed: false)
        }
        stepStartedAt = nil
        carriedElapsed = 0
        sessionStartedAt = nil
        elapsedInStep = 0
        stepIndex = 0
        state = .idle
    }

    /// Kullanıcı bir tekrarı atlamak isterse.
    func skipStep() {
        guard state == .running || state == .paused else { return }
        advance()
    }

    // MARK: Motor

    private func startTicking() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func beginCurrentStep() {
        stepStartedAt = Date()
        carriedElapsed = 0
        elapsedInStep = 0
        lastSpokenSecond = -1
        if let step = currentStep {
            feedback.cue(for: step.phase, duration: step.duration)
        }
    }

    private func tick() {
        guard state == .running, let start = stepStartedAt, let step = currentStep else { return }
        elapsedInStep = carriedElapsed + Date().timeIntervalSince(start)

        // Son 3 saniyede geri sayım tık'ı — kullanıcının ekrana bakması gerekmesin.
        let remaining = Int(ceil(step.duration - elapsedInStep))
        if remaining <= 3, remaining > 0, remaining != lastSpokenSecond {
            lastSpokenSecond = remaining
            feedback.countdownTick()
        }

        if elapsedInStep >= step.duration {
            advance()
        }
    }

    private func advance() {
        let next = stepIndex + 1
        if next >= steps.count {
            finish()
        } else {
            stepIndex = next
            beginCurrentStep()
        }
    }

    private func finish() {
        timer?.cancel()
        timer = nil
        stepStartedAt = nil
        state = .finished
        UIApplication.shared.isIdleTimerDisabled = false
        feedback.cue(for: .finished, duration: 0)
        emitRecord(completed: true)
    }

    private func emitRecord(completed: Bool) {
        let duration = sessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let record = SessionRecord(
            levelID: level.id,
            completedReps: completed ? level.totalReps : completedReps,
            plannedReps: level.totalReps,
            duration: duration,
            wasCompleted: completed
        )
        onFinish?(record)
    }
}
