import Core
import DesignSystem
import SwiftUI

/// The guided walk-through for locating the right muscles.
///
/// KICKOFF_PROMPT calls this out as a headline differentiator: most people
/// squeeze the wrong thing, get nothing out of it, and delete the app. So it's
/// a real step in onboarding rather than a help article nobody opens.
///
/// Every word comes from `content.json` — see `MuscleGuide` for the content
/// rule about what this text may and may not say.
struct MuscleGuideView: View {
    let guide: MuscleGuide
    /// `nil` when opened from Settings, where there's nothing to continue to.
    var onContinue: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            ScreenTitle(verbatim: guide.title.resolved())

            Text(verbatim: guide.intro.resolved())
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)

            VStack(alignment: .leading, spacing: SpacingToken.md) {
                ForEach(guide.steps) { step in
                    stepRow(step)
                }
            }

            Text(verbatim: guide.closing.resolved())
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)

            if let onContinue {
                PrimaryButton("guide.continue", action: onContinue)
                    .padding(.top, SpacingToken.sm)
            }
        }
    }

    private func stepRow(_ step: MuscleGuide.Step) -> some View {
        HStack(alignment: .top, spacing: SpacingToken.md) {
            Text(verbatim: "\(step.id)")
                .font(TypographyToken.bodyEmphasized)
                .foregroundStyle(ColorToken.accent)
                .monospacedDigit()
                .frame(minWidth: SpacingToken.lg, alignment: .leading)

            VStack(alignment: .leading, spacing: SpacingToken.xs) {
                Text(verbatim: step.title.resolved())
                    .font(TypographyToken.bodyEmphasized)
                    .foregroundStyle(ColorToken.primaryText)
                Text(verbatim: step.body.resolved())
                    .font(TypographyToken.body)
                    .foregroundStyle(ColorToken.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
