// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Feedback",
    // Required for a target that carries localized resources. Feedback keeps
    // its own catalog rather than reading the app's: it looks strings up with
    // an explicit `bundle: .module`, so unlike SwiftUI's `Text` it resolves
    // correctly from inside the package.
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Feedback", targets: ["Feedback"]),
    ],
    dependencies: [
        .package(path: "../Core"),
    ],
    targets: [
        .target(
            name: "Feedback",
            dependencies: ["Core"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .testTarget(name: "FeedbackTests", dependencies: ["Feedback"]),
    ],
    swiftLanguageModes: [.v6]
)
