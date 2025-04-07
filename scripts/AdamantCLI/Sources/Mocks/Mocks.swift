//
//  Mocks.swift
//  AdamantCLI
//
//  Created by Brian on 01/04/2025.
//

import ArgumentParser
import Foundation

struct Mocks: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate mock files using Sourcery.",
        usage: "adamant-cli mocks",
        discussion: """
            This command generates mock files for your project using Sourcery.
            Ensure Sourcery is installed and properly configured before running this command.
            """
    )

    func run() throws {
        try checkSourceryInstallation()
        try executeProcess(
            launchPath: "/opt/homebrew/bin/sourcery",
            arguments: ["--config", ".sourcery.yml"],
            successMessage: "✅ Mocks are generated successfully.",
            failureMessage: "Failed to generate mocks using Sourcery."
        )
    }

    private func checkSourceryInstallation() throws {
        try executeProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "command -v sourcery"],
            successMessage: nil,
            failureMessage: "🚨 Sourcery is not installed. Please install Sourcery first using the setup command."
        )
    }

    private func executeProcess(
        launchPath: String,
        arguments: [String],
        successMessage: String?,
        failureMessage: String
    ) throws {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments

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
            throw ValidationError(failureMessage)
        } else if let successMessage = successMessage {
            print(successMessage)
        }
    }
}
