// swift-tools-version: 5.9
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
            type: .dynamic,
            targets: ["CommonKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/krzyzanowskim/CryptoSwift.git",
            .upToNextMajor(from: "1.5.0") // 1.8.4
        ),
        .package(
            url: "https://github.com/SnapKit/SnapKit.git",
            .upToNextMajor(from: "5.0.0") // 5.7.1
        ),
        .package(
            url: "https://github.com/jedisct1/swift-sodium.git",
            .upToNextMajor(from: "0.9.1") // 0.9.1
        ),
        .package(
            url: "https://github.com/maniramezan/DateTools.git",
            branch: "mani_swiftpm_5_3" // kk 5.3 swift
        ),
        .package(
            url: "https://github.com/bmoliveira/MarkdownKit.git",
            .upToNextMajor(from: "1.7.0") // 1.7.1 kk
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            .upToNextMajor(from: "4.2.2") // 4.2.2
        ),
        .package(
            url: "https://github.com/RNCryptor/RNCryptor.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            .upToNextMajor(from: "5.10.0") // 5.10.1
        ),
        .package(
            url: "https://github.com/apple/swift-async-algorithms",
            .upToNextMajor(from: "1.0.3")
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
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "CryptoSwift",
                "SnapKit",
                "MarkdownKit",
                "KeychainAccess",
                "RNCryptor",
                "Alamofire",
                "BitcoinKit"
            ],
            resources: [
                .process("./Assets/GitData.plist")
            ]
        ),
        .testTarget(
            name: "CommonKitTests",
            dependencies: ["CommonKit"]
        )
    ]
)
