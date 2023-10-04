// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ChatKit",
            targets: ["ChatKit"]
        )
    ],
    dependencies: [
        .package(path: "../CommonKit")
    ],
    targets: [
        .target(
            name: "ChatKit",
            dependencies: ["CommonKit"]
        )
    ]
)
