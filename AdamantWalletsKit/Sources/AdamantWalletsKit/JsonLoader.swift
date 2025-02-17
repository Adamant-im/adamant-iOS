//
//  AssetLoader.swift
//  AdamantWalletsKit
//
//  Created by Владимир Клевцов on 17.1.25..
//
import Foundation

public struct JsonLoader {
    public static func loadFilesFromGeneral() -> [Data] {
      guard let generalResourceURL = Bundle.module.url(forResource: "general", withExtension: nil) else {
        print("Failed to find 'general' folder.")
        return []
      }
      return loadInfoFiles(resourceURL: generalResourceURL)
    }
    
    public static func loadFilesFromBlockchainsEthereum() -> [Data] {
      guard let blockchainsResourceURL = Bundle.module.url(forResource: "blockchains/ethereum", withExtension: nil) else {
        print("Failed to find 'blockchains' folder.")
        return []
      }
      return loadInfoFiles(resourceURL: blockchainsResourceURL)
    }
    
    static func loadInfoFiles(resourceURL: URL) -> [Data] {
      var jsonDataFiles = [Data]()
      do {
        let enumerator = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
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
