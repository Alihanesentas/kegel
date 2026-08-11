import SwiftUI
import Testing
@testable import DesignSystem

// This package is iOS-only (UIKit-bridged colors) and can only be built and
// run inside Xcode — not verified in an environment without the iOS SDK.

struct SpacingTokenTests {
    @Test func spacingScaleIsMonotonicallyIncreasing() {
        #expect(SpacingToken.xs < SpacingToken.sm)
        #expect(SpacingToken.sm < SpacingToken.md)
        #expect(SpacingToken.md < SpacingToken.lg)
        #expect(SpacingToken.lg < SpacingToken.xl)
    }

    @Test func minTouchTargetMeetsAppleGuidance() {
        #expect(SpacingToken.minTouchTarget == 44)
    }
}

@MainActor
struct ComponentConstructionTests {
    @Test func componentsConstructWithoutCrashing() {
        _ = PrimaryButton("Start") {}
        _ = Card { Text("content") }
        _ = ScreenTitle("Title")
    }
}
