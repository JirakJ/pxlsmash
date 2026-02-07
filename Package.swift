// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "optipix",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "optipix",
            dependencies: [
                "OptiPixCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "OptiPixCore",
            dependencies: [],
            resources: [
                .process("Metal/Shaders"),
            ]
        ),
        .testTarget(
            name: "OptiPixTests",
            dependencies: ["OptiPixCore"],
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
