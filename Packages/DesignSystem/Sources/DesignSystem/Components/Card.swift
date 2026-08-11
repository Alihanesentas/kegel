import SwiftUI

public struct Card<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SpacingToken.md)
            .background(ColorToken.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
