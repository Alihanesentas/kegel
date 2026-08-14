// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sync",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Sync", targets: ["Sync"]),
    ],
    targets: [
        .target(name: "Sync"),
        .testTarget(name: "SyncTests", dependencies: ["Sync"]),
    ],
    swiftLanguageModes: [.v6]
)
