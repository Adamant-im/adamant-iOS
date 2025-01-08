// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BitcoinKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "BitcoinKit", targets: ["BitcoinKit"])
    ],
    dependencies: [
        .package(name: "OpenSSL", url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "3.3.0")),
        .package(name: "Web3swift", url: "https://github.com/skywinder/web3swift.git", .upToNextMajor(from: "3.0.0")) //,
    ],
    targets: [
        .target(
            name: "BitcoinKit",
            dependencies: ["BitcoinKitPrivate", .product(name: "web3swift", package: "Web3swift")]
        ),
        .target(
            name: "BitcoinKitPrivate",
            dependencies: ["OpenSSL", .product(name: "web3swift", package: "Web3swift")]
        )
    ]
)
