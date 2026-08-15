// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Feedback",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Feedback", targets: ["Feedback"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Feedback",
            dependencies: ["Core"]
        ),
        .testTarget(name: "FeedbackTests", dependencies: ["Feedback"])
    ],
    swiftLanguageModes: [.v6]
)
