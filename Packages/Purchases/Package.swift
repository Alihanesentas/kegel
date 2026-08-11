// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Purchases",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Purchases", targets: ["Purchases"])
    ],
    targets: [
        .target(name: "Purchases"),
        .testTarget(name: "PurchasesTests", dependencies: ["Purchases"])
    ],
    swiftLanguageModes: [.v6]
)
