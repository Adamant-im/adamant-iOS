// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiskKit",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "LiskKit",
            targets: ["LiskKit"]),
    ],
    dependencies: [
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "LiskKit",
            dependencies: [
                .product(name: "Clibsodium", package: "Sodium"),
                "CryptoSwift"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LiskKitTests",
            dependencies: ["LiskKit"],
            path: "Tests"
        )
        
    ]
)
