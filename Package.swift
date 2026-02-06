// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "imgcrush",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "imgcrush",
            dependencies: [
                "ImgCrushCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "ImgCrushCore",
            dependencies: [],
            resources: [
                .process("Metal/Shaders"),
            ]
        ),
        .testTarget(
            name: "ImgCrushTests",
            dependencies: ["ImgCrushCore"],
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
