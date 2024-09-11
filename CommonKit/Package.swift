// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommonKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces,
        // making them visible to other packages.
        .library(
            name: "CommonKit",
            targets: ["CommonKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/krzyzanowskim/CryptoSwift.git",
            .upToNextMinor(from: "1.5.0")
        ),
        .package(
            url: "https://github.com/SnapKit/SnapKit.git",
            .upToNextMajor(from: "5.0.0")
        ),
        .package(
            url: "https://github.com/jedisct1/swift-sodium.git",
            .upToNextMinor(from: "0.9.1")
        ),
        .package(
            url: "https://github.com/maniramezan/DateTools.git",
            branch: "mani_swiftpm_5_3"
        ),
        .package(
            url: "https://github.com/bmoliveira/MarkdownKit.git",
            .upToNextMinor(from: "1.7.0")
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            .upToNextMinor(from: "4.2.2")
        ),
        .package(
            url: "https://github.com/RNCryptor/RNCryptor.git",
            .upToNextMinor(from: "5.1.0")
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            .upToNextMinor(from: "5.4.2")
        ),
        .package(path: "../BitcoinKit")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CommonKit",
            dependencies: [
                .product(name: "Clibsodium", package: "swift-sodium"),
                .product(name: "DateToolsSwift", package: "DateTools"),
                "CryptoSwift",
                "SnapKit",
                "MarkdownKit",
                "KeychainAccess",
                "RNCryptor",
                "Alamofire",
                "BitcoinKit"
            ]
        ),
        .testTarget(
            name: "CommonKitTests",
            dependencies: ["CommonKit"]
        )
    ]
)
