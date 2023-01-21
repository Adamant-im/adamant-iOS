// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PopupKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PopupKit",
            targets: ["PopupKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PopupKit",
            dependencies: []
        )
    ]
)
