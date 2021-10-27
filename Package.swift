// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Clangler",
    products: [
        .executable(name: "ClanglerClient", targets: ["ClanglerClient"]),
        .library(name: "Clangler", targets: ["Clangler"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .target(name: "ClanglerClient", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "Clangler"),
        .testTarget(name: "ClanglerTests", dependencies: ["Clangler"]),
    ]
)
