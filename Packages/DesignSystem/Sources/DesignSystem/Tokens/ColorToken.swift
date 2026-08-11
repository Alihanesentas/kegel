import SwiftUI
import UIKit

/// Semantic color tokens. Clinical and high-contrast — neither wellness
/// pastel nor gym neon. See CLAUDE.md section 1. Every token is a system
/// dynamic color so dark mode (section 8) works without extra handling.
public enum ColorToken {
    public static let background = Color(uiColor: .systemBackground)
    public static let surface = Color(uiColor: .secondarySystemBackground)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let border = Color(uiColor: .separator)
    public static let accent = Color(uiColor: UIColor(red: 0.16, green: 0.42, blue: 0.52, alpha: 1))
}
