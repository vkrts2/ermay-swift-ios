// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ErmayMobil",
    defaultLocalization: "tr",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ErmayMobil",
            targets: ["ErmayMobil"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "ErmayMobil",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ],
            path: "Sources/ErmayMobil",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ErmayMobilTests",
            dependencies: ["ErmayMobil"],
            path: "Tests/ErmayMobilTests"
        ),
    ]
)
