// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    // iOS only — these are SwiftUI screens that use UIKit bridges
    // (idle timer, haptics). Verified by building the app in Xcode.
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Persistence"),
        .package(path: "../Purchases"),
        .package(path: "../Notifications"),
        .package(path: "../Analytics")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["Core", "DesignSystem", "Persistence", "Purchases", "Notifications", "Analytics"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features", "Core", "Persistence", "Purchases", "Notifications", "Analytics"]
        )
    ],
    swiftLanguageModes: [.v6]
)
