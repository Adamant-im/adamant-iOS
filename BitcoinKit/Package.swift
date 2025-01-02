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
        .package(name: "OpenSSL", url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "1.1.180")),
        .package(name: "Web3swift", url: "https://github.com/skywinder/web3swift.git", .exact("3.2.2"))
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
