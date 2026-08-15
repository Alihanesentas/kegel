// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    // iOS only, deliberately — this package uses UIKit-bridged SwiftUI colors
    // (`Color(uiColor:)`), so unlike the other packages it can't build for a
    // macOS host. It can only be verified inside Xcode, not via `swift test`
    // in this environment.
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(name: "DesignSystem"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"])
    ],
    swiftLanguageModes: [.v6]
)
