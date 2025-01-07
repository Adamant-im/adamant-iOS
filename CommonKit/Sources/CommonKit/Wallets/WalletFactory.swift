//
//  WalletFactory.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 6.1.25..
//
import Foundation
import AdamantWalletsAssets

struct WalletFactory {
    private static var cachedWalletDictionary: [String: WalletDecodingModel] = {
        let jsonFiles = AssetManager.loadInfoFiles()
        return Self.createDictionary(from: jsonFiles)
    }()
    
    func wallet(for symbol: String) -> WalletDecodingModel? {
        return Self.cachedWalletDictionary[symbol]
    }
    
    private static func createDictionary(from jsonFiles: [Any]) -> [String: WalletDecodingModel] {
        var dictionary: [String: WalletDecodingModel] = [:]
        
        for jsonObject in jsonFiles {
            do {
                guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
                    print("Ошибка преобразования объекта в Data")
                    continue
                }
                
                let wallet = try JSONDecoder().decode(WalletDecodingModel.self, from: jsonData)
                
                dictionary[wallet.symbol] = wallet
            } catch {
                print("Ошибка декодирования объекта: \(error)")
            }
        }
        
        return dictionary
    }
}
