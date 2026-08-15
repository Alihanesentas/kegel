import Core
import DesignSystem
import SwiftUI

/// The "train" tab: pick a level and start.
///
/// Every level is visible and every unlocked level is startable — progression
/// suggests, it doesn't gate (CLAUDE.md section 5). The only thing that locks
/// a row is the subscription boundary from `content.json`.
public struct LevelListView: View {
    @Environment(AppModel.self) private var model
    @State private var startedLevel: Level?
    @State private var lockedLevel: Level?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingToken.md) {
                    recommendation
                    ForEach(model.content.levels) { level in
                        levelRow(level)
                    }
                }
                .padding(SpacingToken.md)
            }
            .background(ColorToken.background)
            .navigationTitle("levels.title")
            .navigationDestination(item: $startedLevel) { level in
                SessionView(level: level, engine: model.makeEngine(for: level))
            }
            .sheet(item: $lockedLevel) { _ in
                PaywallView {}
            }
        }
    }

    private var recommendation: some View {
        let level = model.recommendedLevel
        return Card(highlighted: true) {
            VStack(alignment: .leading, spacing: SpacingToken.sm) {
                Text("levels.recommended")
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
                Text(verbatim: level.title.resolved())
                    .font(TypographyToken.sectionTitle)
                PrimaryButton("levels.start") { start(level) }
            }
        }
    }

    private func levelRow(_ level: Level) -> some View {
        let unlocked = model.isUnlocked(levelID: level.id)
        return Button {
            start(level)
        } label: {
            HStack(spacing: SpacingToken.md) {
                VStack(alignment: .leading, spacing: SpacingToken.xs) {
                    Text(verbatim: level.title.resolved())
                        .font(TypographyToken.bodyEmphasized)
                        .foregroundStyle(ColorToken.primaryText)
                    Text(verbatim: level.subtitle.resolved())
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                    Text("levels.detail \(level.totalReps) \(minutesText(level))")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                }
                Spacer(minLength: SpacingToken.sm)
                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .foregroundStyle(ColorToken.secondaryText)
            }
            .frame(minHeight: SpacingToken.minTouchTarget)
            .padding(SpacingToken.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorToken.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ColorToken.cardBorder, lineWidth: 1)
            }
            .cardElevation()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(unlocked ? "levels.hint.start" : "levels.hint.locked")
    }

    private func minutesText(_ level: Level) -> String {
        String(max(1, Int((level.totalDuration / 60).rounded())))
    }

    private func start(_ level: Level) {
        if model.isUnlocked(levelID: level.id) {
            startedLevel = level
        } else {
            lockedLevel = level
        }
    }
}
