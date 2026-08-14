import SwiftUI

/// Primary capsule button with the turquoise-to-black gradient.
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
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ColorToken.accent, ColorToken.brandBlack],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .opacity(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
                .animation(reduceMotion ? nil : .easeInOut(duration: MotionToken.fast), value: configuration.isPressed)
        }
    }
}
