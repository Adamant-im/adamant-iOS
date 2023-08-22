// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdvancedContextMenuKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AdvancedContextMenuKit",
            targets: ["AdvancedContextMenuKit"]
        )
    ],
    dependencies: [
        .package(path: "../CommonKit")
    ],
    targets: [
        .target(
            name: "AdvancedContextMenuKit",
            dependencies: ["CommonKit"]
        )
    ]
)
