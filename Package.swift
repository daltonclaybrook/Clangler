// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "Clangler",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .executable(name: "ClanglerClient", targets: ["ClanglerClient"]),
        .library(name: "Clangler", targets: ["Clangler"])
    ],
    targets: [
        .executableTarget(name: "ClanglerClient", dependencies: ["Clangler"]),
        .target(name: "Clangler"),
        .testTarget(name: "ClanglerTests", dependencies: ["Clangler"]),
    ]
)
