// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Analytics", targets: ["Analytics"])
    ],
    targets: [
        .target(name: "Analytics"),
        .testTarget(name: "AnalyticsTests", dependencies: ["Analytics"])
    ],
    swiftLanguageModes: [.v6]
)
