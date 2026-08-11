import DesignSystem
import SwiftUI

/// Placeholder shell. The real vertical slice (level select → run a session →
/// see phase cues) is KICKOFF_PROMPT.md step 6 and hasn't been built yet —
/// this only proves the packages wire together.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(spacing: SpacingToken.lg) {
            ScreenTitle("root.title")
            Text("root.subtitle")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingToken.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorToken.background)
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment())
}
