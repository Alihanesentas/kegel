import SwiftUI
import UIKit

/// Semantic color tokens. Clinical and high-contrast — neither wellness
/// pastel nor gym neon. See CLAUDE.md section 1. Dynamic colors adapt to
/// dark mode (section 8) without extra handling.
public enum ColorToken {
    public static let background = Color(uiColor: .systemBackground)
    public static let surface = Color(uiColor: .secondarySystemBackground)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let border = Color(uiColor: .separator)

    private static let lightAccent = UIColor(red: 0.00, green: 0.55, blue: 0.56, alpha: 1)
    private static let darkAccent = UIColor(red: 0.20, green: 0.83, blue: 0.80, alpha: 1)

    public static let accent = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkAccent : lightAccent
    })

    public static let onAccent = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .black : .white
    })

    private static let lightAccentSoft = UIColor(red: 0.88, green: 0.98, blue: 0.98, alpha: 1)
    private static let darkAccentSoft = UIColor(red: 0.10, green: 0.20, blue: 0.20, alpha: 1)

    public static let accentSoft = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? darkAccentSoft : lightAccentSoft
    })

    private static let brandBlackColor = UIColor(red: 0.07, green: 0.09, blue: 0.10, alpha: 1)

    public static let brandBlack = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .systemBackground : brandBlackColor
    })
}
