// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "KeyLaunch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KeyLaunchCore",
            targets: ["KeyLaunchCore"]
        ),
        .executable(
            name: "KeyLaunch",
            targets: ["KeyLaunchApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "KeyLaunchCore",
            path: "KeyLaunch/Core"
        ),
        .executableTarget(
            name: "KeyLaunchApp",
            dependencies: [
                "KeyLaunchCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "KeyLaunch/App"
        ),
        .testTarget(
            name: "KeyLaunchCoreTests",
            dependencies: ["KeyLaunchCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
