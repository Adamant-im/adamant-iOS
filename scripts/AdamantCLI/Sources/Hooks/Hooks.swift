//
//  Hooks.swift
//  AdamantCLI
//
//  Created by Brian on 31/03/2025.
//

import ArgumentParser
import Foundation

public struct Hooks: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Git hook installer for Adamant-CLI Toolkit.",
        usage: "adamant-cli hooks [<hook-type>]",
        discussion: """
            Use this command to install git hooks for the Adamant-CLI Toolkit.
            Available hook types:
              - formatter: Installs the pre-commit formatter hook.
              - message: Installs the commit message validation hook.
            Example:
              adamant-cli hooks formatter
            """
    )

    enum Hook: String, ExpressibleByArgument {
        case message
        case formatter

        var sourceFilename: String {
            switch self {
            case .message: "commit-msg"
            case .formatter: "pre-commit-formatter"
            }
        }

        var targetFilename: String {
            switch self {
            case .message: "commit-msg"
            case .formatter: "pre-commit"
            }
        }

        var sourceFolder: String { ".githooks" }
        var targetFolder: String { ".git/hooks" }
    }

    @Argument(help: "Git hook type. Options are 'message' or 'formatter'. Default is 'formatter'.")
    var hook: Hook

    public init() {}

    public mutating func run() throws {
        try install(hook)
    }

    private func install(_ hook: Hook) throws {
        // Get the current working directory of the binary
        let currentDirectory = FileManager.default.currentDirectoryPath
        let githooksPath = "\(currentDirectory)"

        guard FileManager.default.fileExists(atPath: githooksPath) else {
            throw ValidationError(
                """
                🚨 Invalid current directory. The command must be run from the directory where the .xcodeproj file is located, 
                which is typically the root of the project directory.
                """
            )
        }

        // Define the source and destination paths
        let sourcePath = "\(currentDirectory)/\(hook.sourceFolder)/\(hook.sourceFilename)"
        let destinationPath = "\(currentDirectory)/\(hook.targetFolder)/\(hook.targetFilename)"

        do {
            // Remove the destination file if it already exists
            if FileManager.default.fileExists(atPath: destinationPath) {
                try FileManager.default.removeItem(atPath: destinationPath)
            }

            // Copy the file from source to destination
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
            // Make the copied file executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationPath)
            print("✅ Successfully copied \(sourcePath) to \(destinationPath)")
        } catch {
            print("🚨 Error: \(error.localizedDescription) at path: \(sourcePath)")
            throw ValidationError(error.localizedDescription)
        }
    }
}
