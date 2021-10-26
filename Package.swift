// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Clangler",
    products: [
        .executable(name: "Clangler", targets: ["Clangler"]),
        .library(name: "ClanglerKit", targets: ["ClanglerKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Clangler", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "ClanglerKit"),
        .testTarget(name: "ClanglerTests", dependencies: ["Clangler"]),
    ]
)
