// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Notifications",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Notifications", targets: ["Notifications"]),
    ],
    targets: [
        .target(name: "Notifications"),
        .testTarget(name: "NotificationsTests", dependencies: ["Notifications"]),
    ],
    swiftLanguageModes: [.v6]
)
