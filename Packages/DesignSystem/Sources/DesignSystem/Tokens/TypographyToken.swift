import SwiftUI

/// Dynamic-Type-safe text styles. Never use `.font(.system(size:))` directly
/// in a screen — CLAUDE.md section 8 requires everything to scale to the
/// largest accessibility size.
public enum TypographyToken {
    public static let screenTitle = Font.system(.largeTitle, weight: .bold)
    public static let sectionTitle = Font.system(.title2, weight: .semibold)
    public static let body = Font.system(.body)
    public static let bodyEmphasized = Font.system(.body, weight: .semibold)
    public static let caption = Font.system(.callout)
}
