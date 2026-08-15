import Core
import DesignSystem
import SwiftUI

/// The progress tab: what the user has actually done.
///
/// Everything here is a plain aggregate. The app shows the data and leaves the
/// interpretation to the user — it never comments on what the numbers mean
/// (CLAUDE.md section 1).
public struct ProgressDashboardView: View {
    @Environment(AppModel.self) private var model

    public init() {}

    private var summary: WeeklySummary {
        model.sessions.weeklySummary(goal: model.content.weeklySessionGoal)
    }

    @State private var showPaywall = false

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingToken.md) {
                    if !model.isUnlocked(.progress) {
                        lockedState
                    } else if model.sessions.records.isEmpty {
                        emptyState
                    } else {
                        weekCard
                        recordsCard
                    }
                }
                .padding(SpacingToken.md)
            }
            .background(ColorToken.background)
            .navigationTitle("progress.title")
            .sheet(isPresented: $showPaywall) {
                PaywallView {}
            }
        }
    }

    /// Progress history can be a paid feature — which one it is comes from
    /// content.json (CLAUDE.md section 6). Sessions are still recorded either
    /// way, so nothing is lost while locked.
    private var lockedState: some View {
        Card {
            VStack(alignment: .leading, spacing: SpacingToken.md) {
                Text("progress.locked.title")
                    .font(TypographyToken.sectionTitle)
                Text("progress.locked.body")
                    .font(TypographyToken.body)
                    .foregroundStyle(ColorToken.secondaryText)
                PrimaryButton("progress.locked.action") { showPaywall = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        Card {
            Text("progress.empty")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var weekCard: some View {
        let week = summary
        return Card {
            VStack(alignment: .leading, spacing: SpacingToken.sm) {
                Text("progress.thisWeek")
                    .font(TypographyToken.sectionTitle)

                Text("progress.week.count \(week.sessionsThisWeek) \(week.goal)")
                    .font(TypographyToken.body)
                    .foregroundStyle(ColorToken.secondaryText)
                    .monospacedDigit()

                ProgressView(value: week.progress)
                    .progressViewStyle(.accentBar)

                if week.streakWeeks > 0 {
                    Text("progress.streak \(week.streakWeeks)")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recordsCard: some View {
        let records = model.sessions.personalRecords
        return Card {
            VStack(alignment: .leading, spacing: SpacingToken.md) {
                Text("progress.records")
                    .font(TypographyToken.sectionTitle)

                statRow("progress.totalSessions", value: "\(records.completedSessions)")
                statRow("progress.totalReps", value: "\(records.totalReps)")
                statRow("progress.bestReps", value: "\(records.mostRepsInASession)")
                if let highest = records.highestCompletedLevelID,
                   let level = model.content.level(id: highest) {
                    statRow("progress.highestLevel", value: level.title.resolved())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
}
