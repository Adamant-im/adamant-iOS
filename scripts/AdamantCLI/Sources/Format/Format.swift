//
//  Format.swift
//  AdamantCLI
//
//  Created by Brian on 31/03/2025.
//

import ArgumentParser
import Foundation

struct Format: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Format Swift files in the project.",
        usage: "adamant-cli format [<all|staged>] [<file1> <file2> ...]",
        discussion: """
            This script formats Swift files in the project using SwiftFormat.
            Use 'all' to format all files in the project, excluding ignored folders.
            Use 'staged' to format only staged Swift files in git.
            """
    )

    enum CodingKeys: CodingKey {
        case type
        case files
    }

    let ignoredFolders: [String] = [
        "Pods"
    ]

    enum RunType: String, ExpressibleByArgument {
        case all
        case staged
    }

    @Argument(
        help:
            "Specify the type of run: 'all' to format all files, 'staged' to format only staged files."
    )
    var type: RunType

    @Argument(help: "List of file paths to format when using 'staged' type.")
    var files: [String] = []

    func run() throws {
        let configurationFilename = ".swiftformat"
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let swiftFormatConfigPath = (currentDirectory as NSString).appendingPathComponent(
            configurationFilename
        )

        guard fileManager.fileExists(atPath: swiftFormatConfigPath) else {
            throw ValidationError(
                "🚨 Error: .swiftformat configuration file not found in the current directory. Ensure you are running this script from the root of the project."
            )
        }

        switch type {
        case .all:
            let directories = try fileManager.contentsOfDirectory(atPath: currentDirectory)
                .filter { fileName in
                    var isDirectory: ObjCBool = false
                    let fullPath = (currentDirectory as NSString).appendingPathComponent(fileName)
                    return fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                        && isDirectory.boolValue && !ignoredFolders.contains(fileName)
                }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["swift", "format", "--recursive", "--configuration", configurationFilename] + directories.flatMap { ["-i", $0] }

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ Swift files formatted successfully.")
            } else {
                print("🚨 Failed to format Swift files. Exit code: \(process.terminationStatus)")
            }

        case .staged:
            guard !files.isEmpty else {
                print("✅ No files specified for formatting.")
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["swift", "format", "--configuration", configurationFilename] + files.flatMap { ["-i", $0] }

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ Specified Swift files formatted successfully.")
            } else {
                print("🚨 Failed to format specified Swift files. Exit code: \(process.terminationStatus)")
            }
        }
    }
}
