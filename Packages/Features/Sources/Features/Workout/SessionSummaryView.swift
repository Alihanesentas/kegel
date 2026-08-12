import Core
import DesignSystem
import SwiftUI

/// Shown once a session ends. Reports what the user did and nothing more —
/// no interpretation, no inference (CLAUDE.md section 1).
struct SessionSummaryView: View {
    @Environment(AppModel.self) private var model

    let level: Level
    let record: SessionRecord
    let onDone: () -> Void

    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingToken.lg) {
                Spacer()

                ScreenTitle(record.wasCompleted ? "summary.title.completed" : "summary.title.stopped")
                    .multilineTextAlignment(.center)

                Text(verbatim: level.title.resolved())
                    .font(TypographyToken.body)
                    .foregroundStyle(ColorToken.secondaryText)

                Card {
                    VStack(spacing: SpacingToken.md) {
                        statRow("summary.reps", value: "\(record.completedReps)/\(record.plannedReps)")
                        Divider()
                        statRow("summary.duration", value: durationText)
                    }
                }
                .padding(.horizontal, SpacingToken.lg)

                learnSection

                Spacer()

                PrimaryButton("summary.done") { finish() }
                    .padding(.horizontal, SpacingToken.lg)
                    .padding(.bottom, SpacingToken.lg)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SpacingToken.lg)
        }
        .background(ColorToken.background)
        .sheet(isPresented: $showPaywall) {
            PaywallView { onDone() }
        }
    }

    private var learnSection: some View {
        VStack(alignment: .leading, spacing: SpacingToken.md) {
            Text("summary.learn.title")
                .font(TypographyToken.sectionTitle)
                .foregroundStyle(ColorToken.primaryText)
                .accessibilityAddTraits(.isHeader)

            InfoCard(
                icon: "wind",
                titleKey: "summary.tip.breath.title",
                bodyKey: "summary.tip.breath.body"
            )
            InfoCard(
                icon: "moon.zzz",
                titleKey: "summary.tip.relax.title",
                bodyKey: "summary.tip.relax.body"
            )
            InfoCard(
                icon: "calendar",
                titleKey: "summary.tip.regular.title",
                bodyKey: "summary.tip.regular.body"
            )
        }
        .padding(.horizontal, SpacingToken.lg)
    }

    private func statRow(_ titleKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(titleKey)
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
            Spacer()
            Text(verbatim: value)
                .font(TypographyToken.bodyEmphasized)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var durationText: String {
        let total = Int(record.duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// The paywall is triggered here — after the user has actually felt the
    /// value — never on launch. CLAUDE.md section 6.
    private func finish() {
        if model.shouldPresentPaywall {
            Task { await model.markPaywallSeen() }
            showPaywall = true
        } else {
            onDone()
        }
    }
}
