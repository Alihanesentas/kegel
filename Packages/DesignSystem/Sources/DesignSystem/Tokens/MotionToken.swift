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
        case .leading: return .trailing
        case .trailing: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}

extension View {
    /// Replaces this view with a sliding transition when `value` changes,
    /// falling back to a fade when Reduce Motion is on.
    public func slideOnChange<Value: Hashable>(_ value: Value, from edge: Edge) -> some View {
        modifier(SlideOnChangeModifier(value: value, edge: edge))
    }
}
