// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    // iOS only — these are SwiftUI screens that use UIKit bridges
    // (idle timer, haptics). Verified by building the app in Xcode.
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Features", targets: ["Features"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Persistence"),
        .package(path: "../Purchases"),
        .package(path: "../Notifications"),
        .package(path: "../Analytics"),
    ],
    targets: [
        // The String Catalog deliberately lives in the app target, not here.
        // SwiftUI resolves `Text("key")` against `Bundle.main`; a catalog
        // shipped as a package resource lands in `Bundle.module` instead, so
        // every string in these screens would render as its raw key. Keeping
        // it in the app is one file instead of a `bundle:` argument on ~90
        // call sites, several of which (Button, Section, Toggle, …) take no
        // bundle at all.
        .target(
            name: "Features",
            dependencies: ["Core", "DesignSystem", "Persistence", "Purchases", "Notifications", "Analytics"]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features", "Core", "Persistence", "Purchases", "Notifications", "Analytics"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
