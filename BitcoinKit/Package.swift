// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "BitcoinKit",
//    platforms: [
//        .iOS(.v10)
//    ],
    products: [
        .library(name: "BitcoinKit", targets: ["BitcoinKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "1.1.180")),
        .package(url: "https://github.com/skywinder/web3swift.git", .upToNextMinor(from: "2.2.0")),
        .package(url: "https://github.com/vapor-community/random.git", .upToNextMinor(from: "1.2.0"))
    ],
    targets: [
        .target(
            name: "BitcoinKit",
            dependencies: ["BitcoinKitPrivate", "web3swift", "Random"]
        ),
        .target(
            name: "BitcoinKitPrivate",
            dependencies: ["OpenSSL", "web3swift"]
        )
    ]
)
