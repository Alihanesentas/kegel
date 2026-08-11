// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    // macOS 14 is declared only so `swift test` works locally/in CI without an
    // iOS simulator. The app target itself targets iOS 17 (see project.yml).
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    targets: [
        .target(
            name: "Core",
            resources: [.process("Program/Resources/content.json")]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        )
    ],
    swiftLanguageModes: [.v6]
)
