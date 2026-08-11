import SwiftUI

public struct ScreenTitle: View {
    private let text: Text

    /// For UI chrome, which lives in a String Catalog.
    public init(_ titleKey: LocalizedStringKey) {
        text = Text(titleKey)
    }

    /// For text that arrives already localized — content from `content.json`,
    /// which carries its own translations and must not be looked up as a key.
    public init(verbatim title: String) {
        text = Text(verbatim: title)
    }

    public var body: some View {
        text
            .font(TypographyToken.screenTitle)
            .foregroundStyle(ColorToken.primaryText)
            .accessibilityAddTraits(.isHeader)
    }
}
