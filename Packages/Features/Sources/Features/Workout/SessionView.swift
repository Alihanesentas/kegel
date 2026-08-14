import Core
import DesignSystem
import SwiftUI

/// The running session.
///
/// Two visual modes: the normal screen, and *dim mode* — a near-black view the
/// user can leave face-up on a desk. CLAUDE.md section 5: dim mode exists
/// because CoreHaptics dies the moment the app leaves the foreground, so
/// "eyes-free" has to mean "foreground but dark", not "locked".
public struct SessionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @State private var driver: SessionDriver
    @State private var isDimmed = false
    @State private var summary: SessionRecord?
    @State private var showPaywall = false

    private let level: Level

    public init(level: Level, engine: WorkoutEngine) {
        self.level = level
        _driver = State(initialValue: SessionDriver(engine: engine))
    }

    private var engine: WorkoutEngine {
        driver.engine
    }

    public var body: some View {
        ZStack {
            (isDimmed ? Color.black : ColorToken.background)
                .ignoresSafeArea()

            if isDimmed {
                dimModeContent
            } else {
                fullContent
            }
        }
        .keepScreenAwake(engine.state == .running)
        .navigationBarBackButtonHidden(true)
        .toolbar(isDimmed ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("session.end") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Dim mode may be a paid feature — the boundary comes from
                // content.json, not from code (CLAUDE.md section 6).
                Button("session.dim") { enterDimMode() }
                    .accessibilityHint(dimModeUnlocked ? "session.dim.hint" : "levels.hint.locked")
            }
        }
        .task { startIfNeeded() }
        .onChange(of: engine.currentPhase) { _, phase in announce(phase) }
        .onChange(of: engine.state) { _, state in
            if state == .finished {
                isDimmed = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Haptics and speech stop when the app leaves the foreground, so a
            // session that kept "running" there would silently lose its cues.
            if phase != .active, engine.state == .running {
                driver.pause()
            }
        }
        // Recording is idempotent: the engine refuses to log a session twice,
        // so a session that ended on its own isn't re-recorded as abandoned.
        .onDisappear { driver.stop(record: true) }
        .fullScreenCover(item: $summary) { record in
            SessionSummaryView(level: level, record: record) {
                // Close the cover first — dismissing the presenting SessionView
                // while its own fullScreenCover is still up leaves the summary
                // stuck on screen instead of returning to what was open before.
                summary = nil
                dismiss()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                // Entering dim mode is the whole reason they got here.
                if dimModeUnlocked {
                    isDimmed = true
                }
            }
        }
    }

    private var dimModeUnlocked: Bool {
        model.isUnlocked(.dimMode)
    }

    private func enterDimMode() {
        if dimModeUnlocked {
            isDimmed = true
        } else {
            showPaywall = true
        }
    }

    // MARK: Layouts

    private var fullContent: some View {
        VStack(spacing: SpacingToken.lg) {
            header

            BreathingRing(phase: engine.currentPhase, stepProgress: engine.stepProgress)
                .frame(maxWidth: 320, maxHeight: 320)
                .overlay { phaseLabel }
                .padding(.horizontal, SpacingToken.lg)

            ProgressView(value: engine.overallProgress)
                .progressViewStyle(.accentBar)
                .padding(.horizontal, SpacingToken.lg)
                .accessibilityLabel("session.overall.progress")

            controls
        }
        .padding(.vertical, SpacingToken.lg)
    }

    /// Almost nothing on screen, everything still running. A tap anywhere
    /// pauses or resumes; the button returns to the full screen.
    private var dimModeContent: some View {
        VStack(spacing: SpacingToken.lg) {
            Spacer()
            Text(engine.currentPhase.label)
                .phaseLabelStyle()
                .foregroundStyle(.white.opacity(0.65))
                .phaseTransition(engine.currentPhase)
            Text(verbatim: remainingText)
                .font(TypographyToken.sectionTitle)
                .foregroundStyle(.white.opacity(0.4))
                .monospacedDigit()
            Spacer()
            Button("session.dim.exit") { isDimmed = false }
                .font(TypographyToken.body)
                .foregroundStyle(.white.opacity(0.5))
                .frame(minHeight: SpacingToken.minTouchTarget)
                .padding(.bottom, SpacingToken.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { driver.togglePause() }
    }

    private var header: some View {
        VStack(spacing: SpacingToken.xs) {
            Text(verbatim: level.title.resolved())
                .font(TypographyToken.sectionTitle)
            Text("session.rep.counter \(engine.currentRep) \(level.reps)")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
                .monospacedDigit()
        }
    }

    private var phaseLabel: some View {
        VStack(spacing: SpacingToken.xs) {
            Text(engine.currentPhase.label)
                .phaseLabelStyle()
                .foregroundStyle(ColorToken.primaryText)
                .phaseTransition(engine.currentPhase)
            Text(verbatim: remainingText)
                .font(TypographyToken.sectionTitle)
                .foregroundStyle(ColorToken.secondaryText)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack(spacing: SpacingToken.md) {
            Button(engine.state == .paused ? "session.resume" : "session.pause") {
                driver.togglePause()
            }
            .buttonStyle(ThemedSecondaryButtonStyle())

            Button("session.skip") { driver.skip() }
                .buttonStyle(ThemedSecondaryButtonStyle())
        }
        .padding(.horizontal, SpacingToken.lg)
    }

    // MARK: Behaviour

    private var remainingText: String {
        engine.state == .finished ? "" : String(Int(ceil(engine.remainingInStep)))
    }

    private func startIfNeeded() {
        guard engine.state == .idle else { return }
        engine.onFinish = { record in
            Task { await model.record(record) }
            summary = record
        }
        driver.start()
    }

    /// Phase changes are the whole point of the screen, so they're announced
    /// rather than left for VoiceOver to discover — CLAUDE.md section 8.
    private func announce(_ phase: Phase) {
        let text = String(localized: String.LocalizationValue(phase.localizationKey), bundle: .main)
        AccessibilityNotification.Announcement(text).post()
    }
}
