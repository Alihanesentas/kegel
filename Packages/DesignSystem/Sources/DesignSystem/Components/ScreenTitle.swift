import SwiftUI

public struct ScreenTitle: View {
    private let titleKey: LocalizedStringKey

    public init(_ titleKey: LocalizedStringKey) {
        self.titleKey = titleKey
    }

    public var body: some View {
        Text(titleKey)
            .font(TypographyToken.screenTitle)
            .foregroundStyle(ColorToken.primaryText)
            .accessibilityAddTraits(.isHeader)
    }
}
