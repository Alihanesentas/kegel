import SwiftUI

/// Elevation for cards and primary buttons.
///
/// A real drop shadow only reads against a light surface — in dark mode a
/// black shadow disappears into the near-black background, so elevation
/// there is a faint turquoise glow instead of a shadow. This is what keeps
/// bordered content from reading as flatly pasted onto the background.
private struct ElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    /// `card` is a quiet lift for surfaces sitting on the page. `prominent`
    /// is a stronger glow/shadow reserved for the one primary action on a
    /// screen, so accent doesn't get flattened out by being used everywhere.
    enum Style {
        case card
        case prominent
    }

    let style: Style

    func body(content: Content) -> some View {
        content.shadow(color: shadowColor, radius: radius, x: 0, y: yOffset)
    }

    private var shadowColor: Color {
        switch (colorScheme, style) {
        case (.dark, .card): ColorToken.accent.opacity(0.10)
        case (.dark, .prominent): ColorToken.accent.opacity(0.28)
        case (_, .card): Color.black.opacity(0.06)
        case (_, .prominent): Color.black.opacity(0.16)
        }
    }

    private var radius: CGFloat {
        switch style {
        case .card: 8
        case .prominent: 14
        }
    }

    private var yOffset: CGFloat {
        switch (colorScheme, style) {
        case (.dark, _): 0
        case (_, .card): 3
        case (_, .prominent): 6
        }
    }
}

public extension View {
    /// Quiet elevation for cards and list rows.
    func cardElevation() -> some View {
        modifier(ElevationModifier(style: .card))
    }

    /// Stronger elevation for the single primary action on a screen.
    func prominentElevation() -> some View {
        modifier(ElevationModifier(style: .prominent))
    }
}
