//
//  Setup.swift
//  AdamantCLI
//
//  Created by Brian on 01/04/2025.
//

import ArgumentParser
import Foundation

struct Setup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Setup script for Adamant-CLI Toolkit.",
        usage: "adamant-cli setup",
        discussion: """
            Use this command to set up the Adamant-CLI Toolkit by installing necessary dependencies such as Sourcery and CocoaPods.
            Ensure Homebrew is installed before running this command.
            """
    )

    func run() throws {
        let brewInstallCommand = """
            if ! command -v brew &> /dev/null; then
                echo "Homebrew is not installed. Please install Homebrew first."
                exit 1
            fi

            echo "Installing Sourcery..."
            brew install sourcery

            echo "Installing CocoaPods..."
            brew install cocoapods

            echo "Installing xcbeautify..."
            brew install xcbeautify

            echo 'import Foundation
            enum AdamantSecret {
                static let appIdentifierPrefix: String = "random.string"
                static let keychainValuePassword: String = "random.string.two"
                static let oldKeychainPass: String = "random.string.three"
            }' > CommonKit/Sources/CommonKit/AdamantSecret.swift
            """

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", brewInstallCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
            throw ValidationError("Failed to install Sourcery or CocoaPods.")
        } else {
            print("✅ Installation successful.")
        }
    }
}
