import SwiftUI

/// Full-width, high-contrast button meeting the 44pt minimum touch target
/// (CLAUDE.md section 1). Text scales with Dynamic Type.
public struct PrimaryButton: View {
    private let titleKey: LocalizedStringKey
    private let action: () -> Void

    public init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(titleKey)
                .frame(maxWidth: .infinity, minHeight: SpacingToken.minTouchTarget)
        }
        .buttonStyle(ThemedButtonStyle())
    }
}
