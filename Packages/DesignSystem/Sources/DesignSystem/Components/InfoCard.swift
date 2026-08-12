import SwiftUI

/// Reusable informational card with an icon, title, and body text.
public struct InfoCard: View {
    private let icon: String
    private let titleKey: LocalizedStringKey
    private let bodyKey: LocalizedStringKey

    public init(icon: String, titleKey: LocalizedStringKey, bodyKey: LocalizedStringKey) {
        self.icon = icon
        self.titleKey = titleKey
        self.bodyKey = bodyKey
    }

    public var body: some View {
        HStack(alignment: .top, spacing: SpacingToken.md) {
            Image(systemName: icon)
                .font(TypographyToken.bodyEmphasized)
                .foregroundStyle(ColorToken.accent)
                .frame(width: SpacingToken.minTouchTarget, height: SpacingToken.minTouchTarget)
                .background(ColorToken.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: SpacingToken.xs) {
                Text(titleKey)
                    .font(TypographyToken.bodyEmphasized)
                    .foregroundStyle(ColorToken.primaryText)
                Text(bodyKey)
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SpacingToken.md)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(ColorToken.accent)
                .frame(width: 4)
                .padding(.vertical, SpacingToken.md)
        }
        .accessibilityElement(children: .combine)
    }
}
