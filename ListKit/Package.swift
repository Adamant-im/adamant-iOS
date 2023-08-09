// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ListKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ListKit",
            targets: ["ListKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ListKit",
            dependencies: []
        )
    ]
)
