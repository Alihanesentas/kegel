// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Purchases",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Purchases", targets: ["Purchases"])
    ],
    dependencies: [
        // The only third-party SDK allowed here (CLAUDE.md section 2), and it
        // stays confined to this package.
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Purchases",
            dependencies: [.product(name: "RevenueCat", package: "purchases-ios")]
        ),
        .testTarget(name: "PurchasesTests", dependencies: ["Purchases"])
    ],
    swiftLanguageModes: [.v6]
)
