// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdamantWalletsKit",
    platforms: [
        .iOS(.v15), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "AdamantWalletsKit",
            targets: ["AdamantWalletsKit"]
        )
    ],
    targets: [
        .target(
            name: "AdamantWalletsKit",
            resources: [
                .copy("JsonStore/general"),
                .copy("JsonStore/blockchains"),
                .process("Wallets.xcassets")
            ]
        )
    ]
)
