import DesignSystem
import SwiftUI

/// The health notice.
///
/// CLAUDE.md section 5: one screen, skippable, stating that this isn't medical
/// advice and that pain or symptoms are a reason to see a doctor. It is *not*
/// a gate and not a screening step — it's the baseline disclosure the App
/// Store health category expects. Reachable again from Settings.
struct HealthNoticeView: View {
    /// `nil` when shown from Settings, where there's nothing to continue to.
    var onContinue: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            ScreenTitle("health.title")

            VStack(alignment: .leading, spacing: SpacingToken.md) {
                Text("health.body.notAdvice")
                Text("health.body.seeDoctor")
                Text("health.body.stopIfPain")
            }
            .font(TypographyToken.body)
            .foregroundStyle(ColorToken.primaryText)

            Spacer()

            if let onContinue {
                PrimaryButton("health.acknowledge", action: onContinue)
            }
        }
    }
}
