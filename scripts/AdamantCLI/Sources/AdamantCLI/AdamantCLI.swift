// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser

@main
struct AdamantCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Adamant-CLI Toolkit.",
        subcommands: [Hooks.self, Format.self, Setup.self, Mocks.self]
    )

    mutating func run() async throws {

    }
}
