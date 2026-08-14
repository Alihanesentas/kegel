import SwiftUI

/// Motion constants and transitions that respect Reduce Motion.
public enum MotionToken {
    public static let fast: Double = 0.2
    public static let medium: Double = 0.35
    public static let slow: Double = 0.5
}

private struct SlideOnChangeModifier<Value: Hashable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Value
    let edge: Edge

    func body(content: Content) -> some View {
        content
            .id(value)
            .transition(reduceMotion ? .opacity : slideTransition(edge))
            .animation(reduceMotion ? nil : .easeInOut(duration: MotionToken.medium), value: value)
    }

    private func slideTransition(_ edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: oppositeEdge(edge)).combined(with: .opacity)
        )
    }

    private func oppositeEdge(_ edge: Edge) -> Edge {
        switch edge {
        case .leading: .trailing
        case .trailing: .leading
        case .top: .bottom
        case .bottom: .top
        }
    }
}

public extension View {
    /// Replaces this view with a sliding transition when `value` changes,
    /// falling back to a fade when Reduce Motion is on.
    func slideOnChange<Value: Hashable>(_ value: Value, from edge: Edge) -> some View {
        modifier(SlideOnChangeModifier(value: value, edge: edge))
    }
}

private struct PhaseTransitionModifier<Value: Hashable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Value

    func body(content: Content) -> some View {
        content
            .id(value)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
            .animation(
                reduceMotion
                    ? .easeInOut(duration: MotionToken.fast)
                    : .spring(response: 0.35, dampingFraction: 0.75),
                value: value
            )
    }
}

public extension View {
    /// A subtle scale + fade used when the workout phase changes. Reduce
    /// Motion never removes the transition outright (CLAUDE.md section 8) —
    /// it just stops moving and becomes a plain fade.
    func phaseTransition<Value: Hashable>(_ value: Value) -> some View {
        modifier(PhaseTransitionModifier(value: value))
    }
}
