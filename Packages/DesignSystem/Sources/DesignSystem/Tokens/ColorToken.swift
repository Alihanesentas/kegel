import SwiftUI
import UIKit

/// Semantic color tokens. Clinical and high-contrast — neither wellness
/// pastel nor gym neon. See CLAUDE.md section 1. Dynamic colors adapt to
/// dark mode (section 8) without extra handling.
public enum ColorToken {
    public static let background = Color(uiColor: .systemBackground)

    /// A step above `background` in both directions — visibly lighter than
    /// pure black in dark mode, visibly off-white in light mode — so a card
    /// reads as its own surface rather than a hairline drawn on the page.
    /// `.secondarySystemBackground` alone was too close to `.systemBackground`
    /// in dark mode (28,28,30 on true black) to read as elevation, which was
    /// a big part of dark mode feeling "flat" rather than "different".
    private static let lightSurface = UIColor(red: 0.965, green: 0.980, blue: 0.980, alpha: 1)
    private static let darkSurface = UIColor(red: 0.11, green: 0.145, blue: 0.150, alpha: 1)

    public static let surface = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkSurface : lightSurface
    })

    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let border = Color(uiColor: .separator)

    private static let lightAccent = UIColor(red: 0.00, green: 0.55, blue: 0.56, alpha: 1)
    private static let darkAccent = UIColor(red: 0.20, green: 0.83, blue: 0.80, alpha: 1)

    public static let accent = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkAccent : lightAccent
    })

    /// Text/icon color for content drawn on a solid `accent` fill (see
    /// `ThemedButtonStyle`). Both `lightAccent` and `darkAccent` are
    /// saturated, mid-to-bright teals, so black clears WCAG AA contrast
    /// (~5:1 light, ~11:1 dark) against either one without branching by
    /// appearance. This intentionally replaced an earlier light/dark split
    /// (white-on-dark, black-on-light) that was tuned for a button whose
    /// background gradient faded to near-black — against a *solid* accent
    /// fill that pairing put white text on a bright teal in dark mode, which
    /// measures under 2:1 contrast and is close to unreadable.
    public static let onAccent = Color.black

    private static let lightAccentSoft = UIColor(red: 0.88, green: 0.98, blue: 0.98, alpha: 1)
    private static let darkAccentSoft = UIColor(red: 0.10, green: 0.20, blue: 0.20, alpha: 1)

    public static let accentSoft = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkAccentSoft : lightAccentSoft
    })

    private static let brandBlackColor = UIColor(red: 0.07, green: 0.09, blue: 0.10, alpha: 1)

    public static let brandBlack = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .systemBackground : brandBlackColor
    })

    /// Hairline border for cards and other blocks — a low-opacity tint of the
    /// accent rather than a generic system gray, so bordered content reads as
    /// part of the same turquoise-on-black/white theme as the buttons.
    private static let lightCardBorder = UIColor(red: 0.00, green: 0.55, blue: 0.56, alpha: 0.16)
    private static let darkCardBorder = UIColor(red: 0.20, green: 0.83, blue: 0.80, alpha: 0.22)

    public static let cardBorder = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkCardBorder : lightCardBorder
    })
}
