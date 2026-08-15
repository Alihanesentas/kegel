import SwiftUI

/// Primary capsule button: solid accent fill, black label.
///
/// This used to be a turquoise-to-black gradient. That reads well in light
/// mode, where the gradient's dark end is a dark charcoal, but in dark mode
/// it faded into a color nearly identical to the screen background — the
/// trailing half of the button all but disappeared, and whichever single
/// text color was chosen was unreadable at one end or the other (see
/// `ColorToken.onAccent`). A solid fill has no such gradient-position
/// dependency and keeps the button legible everywhere, which matters more
/// for this audience than the gradient did (CLAUDE.md section 1: high
/// contrast, 45+ users).
public struct ThemedButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        ThemedButtonLabel(configuration: configuration)
    }

    private struct ThemedButtonLabel: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(TypographyToken.bodyEmphasized)
                .foregroundStyle(ColorToken.onAccent)
                .frame(maxWidth: .infinity, minHeight: SpacingToken.minTouchTarget)
                .background(Capsule().fill(ColorToken.accent))
                .prominentElevation()
                .opacity(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .animation(reduceMotion ? nil : .easeInOut(duration: MotionToken.fast), value: configuration.isPressed)
        }
    }
}
