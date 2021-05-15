Lisk Swift
==========

[![Build Status](https://www.bitrise.io/app/b15eedbea467ee22/status.svg?token=RkzlwvQLLXXn5w1J1z2tpQ&branch=master)](https://www.bitrise.io/app/b15eedbea467ee22)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Lisk.svg)](https://img.shields.io/cocoapods/v/Lisk.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@andrew_barba-blue.svg?style=flat)](http://twitter.com/andrew_barba)

Lisk Swift is a Swift 4 library for Lisk - the cryptocurrency and blockchain application platform. It allows developers to create offline transactions and broadcast them onto the network. It also allows developers to interact with the core Lisk API, for retrieval of collections and single records of data located on the Lisk blockchain. Its main benefit is that it does not require a locally installed Lisk node, and instead utilizes the existing peers on the network. It can be used on any environment that runs Swift 4, including iOS, tvOS, macOS, watchOS.

Lisk Swift is heavily inspired by [Lisk JS](https://github.com/LiskHQ/lisk-js)

## Features

- [x] Local Signing for maximum security
- [x] Targets Lisk 1.0.0 API
- [x] Directly based on lisk-js
- [x] Swift 4.1
- [x] Unit Tests (87% coverage)
- [x] Documentation

## API

- [Accounts](https://andrewbarba.github.io/lisk-swift/Structs/Accounts.html)
- [Blocks](https://andrewbarba.github.io/lisk-swift/Structs/Blocks.html)
- [Dapps](https://andrewbarba.github.io/lisk-swift/Structs/Dapps.html)
- [Delegates](https://andrewbarba.github.io/lisk-swift/Structs/Delegates.html)
- [Node](https://andrewbarba.github.io/lisk-swift/Structs/Node.html)
- [Peers](https://andrewbarba.github.io/lisk-swift/Structs/Peers.html)
- [Signatures](https://andrewbarba.github.io/lisk-swift/Structs/Signatures.html)
- [Transactions](https://andrewbarba.github.io/lisk-swift/Structs/Transactions.html)

## Documentation

[https://andrewbarba.github.io/lisk-swift/](https://andrewbarba.github.io/lisk-swift/)

## Usage

### Import Framework

```swift
import Lisk
```

### Send LSK

```swift
let address = ...
let secret = ...

// Send LSK on the Mainnet
Transactions().transfer(lsk: 1.12, to: address, secret: secret) { response in
    switch response {
    case .success(let result):
        print(result.transactionId)
    case .error(let error):
        print(error.message)
    }
}
```

#### Send LSK on Testnet

```swift
let address = ...
let secret = ...

// Send LSK on the Testnet
Transactions(client: .testnet).transfer(lsk: 1.12, to: address, secret: secret) { response in
    switch response {
    case .success(let result):
        print(result.transactionId)
    case .error(let error):
        print(error.message)
    }
}
```

### Testnet

By default, all modules are initialized with an `APIClient` pointing to the Lisk Mainnet. You can optionally pass in a specific client to any modules constructor:

```swift
let mainTransactions = Transactions()
let testTransactions = Transactions(client: .testnet)
```

To default all modules to a specific client you can set the shared client:

```swift
APIClient.shared = .testnet
```

And then all modules initialized will default to Testnet:

```swift
// This will connect to Testnet
let transactions = Transactions()
```

## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Xcode 9.0+
- Swift 4.0+

## Installation

### Swift Package Manager

```swift
// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "My Lisk App",
    dependencies: [
        .package(url: "https://github.com/AndrewBarba/lisk-swift.git", from: "1.0.0.beta")
    ]
)
```

### CocoaPods

> CocoaPods 1.5.0+ is required to build lisk-swift

```ruby
pod 'Lisk', '~> 1.0.0.beta'
```

### Carthage

```ogdl
github "AndrewBarba/lisk-swift" ~> 1.0.0.beta
```

## Thank You

To show support for continued development feel free to vote for my delegate: [andrew](https://explorer.lisk.io/delegate/14987768355736502769L)

Or donate LSK to `14987768355736502769L`
