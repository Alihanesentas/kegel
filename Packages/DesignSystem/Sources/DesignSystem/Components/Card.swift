import SwiftUI

/// Generic surface container. Set `highlighted` for the one card on a screen
/// that should read as the primary next action (e.g. the recommended level) —
/// it gets an accent-tinted fill and border instead of blending in with
/// every other row at the same visual weight.
public struct Card<Content: View>: View {
    private let content: Content
    private let isHighlighted: Bool

    public init(highlighted: Bool = false, @ViewBuilder content: () -> Content) {
        isHighlighted = highlighted
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SpacingToken.md)
            .background(isHighlighted ? ColorToken.accentSoft : ColorToken.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isHighlighted ? ColorToken.accent.opacity(0.55) : ColorToken.cardBorder,
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
            }
            .cardElevation()
    }
}
