// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "KeyLaunch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "KeyLaunch",
            targets: ["KeyLaunchApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "KeyLaunchApp",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "KeyLaunch",
            sources: ["App", "Core"],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "KeyLaunchCoreTests",
            dependencies: ["KeyLaunchApp"]
        )
    ],
    swiftLanguageModes: [.v6]
)
