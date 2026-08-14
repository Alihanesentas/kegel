import SwiftUI

/// Secondary capsule button: accent stroke over a faint accent-tinted fill.
///
/// A stroke alone on top of `background` reads as a hairline floating on the
/// page rather than a tappable control — easy to miss at a glance, which
/// matters for controls like session pause/skip that sit directly on the
/// screen background. The soft fill gives it the same "this is a button"
/// weight as the surface cards without competing with the solid-fill
/// primary button.
public struct ThemedSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        ThemedSecondaryButtonLabel(configuration: configuration)
    }

    private struct ThemedSecondaryButtonLabel: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(TypographyToken.bodyEmphasized)
                .foregroundStyle(ColorToken.accent)
                .frame(maxWidth: .infinity, minHeight: SpacingToken.minTouchTarget)
                .background(Capsule().fill(ColorToken.accentSoft))
                .overlay(
                    Capsule()
                        .stroke(ColorToken.accent, lineWidth: 2)
                )
                .opacity(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .animation(reduceMotion ? nil : .easeInOut(duration: MotionToken.fast), value: configuration.isPressed)
        }
    }
}
