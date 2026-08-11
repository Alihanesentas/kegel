import SwiftUI
import UIKit

/// Keeps the screen awake for the duration of a session.
///
/// Dim mode (CLAUDE.md section 5) depends on the app staying in the
/// foreground: CoreHaptics stops the moment the device locks, so an
/// auto-locking screen would silently kill the haptic cues mid-session.
struct ScreenWakeLock: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = isActive }
            .onChange(of: isActive) { _, active in
                UIApplication.shared.isIdleTimerDisabled = active
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

extension View {
    func keepScreenAwake(_ isActive: Bool) -> some View {
        modifier(ScreenWakeLock(isActive: isActive))
    }
}
