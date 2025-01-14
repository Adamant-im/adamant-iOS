//
//  AssetLoader.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 14.1.25..
//
import Foundation
import AdamantWalletsAssets

public struct AssetLoader {
    
    public static func loadFilesFromGeneral() -> [Data] {
        guard let generalResourceURL = Bundle.adamantWalletsAssets.url(forResource: "general", withExtension: nil) else {
            print("Failed to find 'general' folder.")
            return []
        }
        return loadInfoFiles(from: generalResourceURL)
    }

    public static func loadFilesFromBlockchainsEthereum() -> [Data] {
        guard let ethereumResourceURL = Bundle.adamantWalletsAssets.url(forResource: "blockchains/ethereum", withExtension: nil) else {
            print("Failed to find 'blockchains/ethereum' folder.")
            return []
        }
        return loadInfoFiles(from: ethereumResourceURL)
    }

    private static func loadInfoFiles(from directoryURL: URL) -> [Data] {
        var jsonDataFiles = [Data]()
        do {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.lastPathComponent == "info.json" {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        jsonDataFiles.append(data)
                    } catch {
                        print("Failed to load data from file at \(fileURL.path): \(error)")
                    }
                }
            }
        }
        return jsonDataFiles
    }
}
