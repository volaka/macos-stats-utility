// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MenuStats",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "MenuStats"),
        .testTarget(name: "MenuStatsTests", dependencies: ["MenuStats"]),
    ]
)
