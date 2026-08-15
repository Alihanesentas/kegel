// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiveSession",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LiveSession", targets: ["LiveSession"])
    ],
    targets: [
        .target(name: "LiveSession"),
        .testTarget(name: "LiveSessionTests", dependencies: ["LiveSession"])
    ],
    swiftLanguageModes: [.v6]
)
