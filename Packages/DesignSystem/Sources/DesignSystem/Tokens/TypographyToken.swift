import SwiftUI
import UIKit

/// Dynamic-Type-safe text styles. Never use `.font(.system(size:))` directly
/// in a screen — CLAUDE.md section 8 requires everything to scale to the
/// largest accessibility size.
public enum TypographyToken {
    public static let screenTitle = Font.system(.largeTitle, weight: .bold)
    public static let sectionTitle = Font.system(.title2, weight: .semibold)
    public static let body = Font.system(.body)
    public static let bodyEmphasized = Font.system(.body, weight: .semibold)
    public static let caption = Font.system(.callout)

    /// The workout phase word ("Squeeze" / "Hold" / "Release"). Heavier and
    /// larger than `screenTitle` and set in the rounded design — this is the
    /// single word a user reads at a glance during a rep, so it needs to read
    /// as a state, not a headline.
    ///
    /// `Font.TextStyle` has no style bigger than `.largeTitle` on iOS, so this
    /// is built from a bigger base point size and scaled with `UIFontMetrics`
    /// against the `.largeTitle` curve — it still grows all the way to the
    /// largest accessibility size, exactly like the `Font.system(text style:)`
    /// tokens above (CLAUDE.md section 8), it just starts bigger.
    public static let phaseLabel = roundedFont(baseSize: 44, weight: .heavy, relativeTo: .largeTitle)

    /// Letter-spacing applied alongside `phaseLabel` via `.phaseLabelStyle()`.
    public static let phaseLabelTracking: CGFloat = 0.5

    private static func roundedFont(baseSize: CGFloat, weight: UIFont.Weight, relativeTo style: UIFont.TextStyle) -> Font {
        let systemFont = UIFont.systemFont(ofSize: baseSize, weight: weight)
        let descriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        let roundedFont = UIFont(descriptor: descriptor, size: baseSize)
        let scaledFont = UIFontMetrics(forTextStyle: style).scaledFont(for: roundedFont)
        return Font(scaledFont)
    }
}

public extension View {
    /// Applies the modern, heavier styling used for the workout phase word.
    /// Centralized here so every call site gets the same font + tracking
    /// instead of reassembling it inline.
    func phaseLabelStyle() -> some View {
        font(TypographyToken.phaseLabel)
            .tracking(TypographyToken.phaseLabelTracking)
    }
}
