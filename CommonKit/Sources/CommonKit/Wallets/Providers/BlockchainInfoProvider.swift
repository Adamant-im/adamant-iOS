//
//  BlockchainInfoProvider.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 17.1.25..
//
import AdamantWalletsKit
import Foundation

public enum BlockchainInfoProvider {
    public static var assets: [BlockchainAssetsDTO] = {
        var assets = [BlockchainAssetsDTO]()
        let jsonDataArray = JsonLoader.loadFilesFromBlockchainsEthereum()
        
        var mainBlockchainInfo: MainBlockchainInfoDTO?
        var childBlockchains = [String: ChildBlockchainDTO]()
        
        let decoder = JSONDecoder()

        for data in jsonDataArray {
            do {
                if mainBlockchainInfo == nil {
                    if let info = try? decoder.decode(MainBlockchainInfoDTO.self, from: data) {
                        mainBlockchainInfo = info
                        continue
                    }
                }
                if let blockchain = try? decoder.decode(ChildBlockchainDTO.self, from: data) {
                    childBlockchains[blockchain.symbol] = blockchain
                }
            }
        }
        
        if let mainInfo = mainBlockchainInfo {
            let assetDTO = BlockchainAssetsDTO(mainInfo: mainInfo, childBlockchains: childBlockchains)
            assets.append(assetDTO)
        } else {
            print("Error: MainBlockchainInfoDTO was not found in JSON files.")
        }
        
        return assets
    }()
}
