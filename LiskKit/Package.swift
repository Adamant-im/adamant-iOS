// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiskKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "LiskKit",
            targets: ["LiskKit"])
    ],
    dependencies: [
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "LiskKit",
            dependencies: [
                .product(name: "Clibsodium", package: "Sodium"),
                "CryptoSwift",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
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
