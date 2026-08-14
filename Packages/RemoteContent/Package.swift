// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteContent",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RemoteContent", targets: ["RemoteContent"]),
    ],
    dependencies: [
        .package(path: "../Core"),
    ],
    targets: [
        .target(name: "RemoteContent", dependencies: ["Core"]),
        .testTarget(name: "RemoteContentTests", dependencies: ["RemoteContent"]),
    ],
    swiftLanguageModes: [.v6]
)
