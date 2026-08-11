import Core
import DesignSystem
import SwiftUI

/// The expanding/contracting ring that paces a rep.
///
/// With Reduce Motion enabled the ring stops moving entirely and the phase is
/// carried by colour and the label instead — CLAUDE.md section 8 requires the
/// animation to have a non-moving equivalent, not just a slower one.
struct BreathingRing: View {
    let phase: Phase
    let stepProgress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let minScale = 0.35
    private static let maxScale = 1.0

    /// Where the ring should sit right now, 0.35-1.0.
    private var scale: Double {
        switch phase {
        case .contract:
            Self.minScale + (Self.maxScale - Self.minScale) * stepProgress
        case .hold:
            Self.maxScale
        case .relax:
            Self.maxScale - (Self.maxScale - Self.minScale) * stepProgress
        case .prepare, .rest:
            Self.minScale
        case .finished:
            0.5
        }
    }

    private var tint: Color {
        switch phase {
        case .contract, .hold: ColorToken.accent
        case .relax: ColorToken.secondaryText
        case .prepare, .rest: ColorToken.border
        case .finished: ColorToken.accent
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorToken.border, lineWidth: 2)

            if reduceMotion {
                // Static disc: size never changes, only the colour does.
                Circle()
                    .fill(tint.opacity(0.25))
                    .padding(24)
                Circle()
                    .stroke(tint, lineWidth: 6)
                    .padding(24)
            } else {
                Circle()
                    .fill(tint.opacity(0.2))
                    .scaleEffect(scale)
                Circle()
                    .stroke(tint, lineWidth: 6)
                    .scaleEffect(scale)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.25), value: phase)
        // The phase label and the VoiceOver announcement carry this
        // information already; the ring itself is decorative.
        .accessibilityHidden(true)
    }
}
