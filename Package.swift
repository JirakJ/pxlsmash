// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pxlsmash",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "pxlsmash",
            dependencies: [
                "PxlSmashCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "PxlSmashCore",
            dependencies: [],
            resources: [
                .process("Metal/Shaders"),
            ]
        ),
        .testTarget(
            name: "PxlSmashTests",
            dependencies: ["PxlSmashCore"],
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
