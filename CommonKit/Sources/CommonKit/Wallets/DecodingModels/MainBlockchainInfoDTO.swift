//
//  MainBlockchainInfoDTO.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 13.1.25..
//
import Foundation
import AdamantWalletsAssets

public struct MainBlockchainInfoDTO: Decodable {
    public let blockchain: String
    public let type: String
    public let mainCoin: String
    public let fees: String
    public let defaultGasLimit: Int
}

public struct ChildBlockchainDTO: Decodable {
    public let name: String
    public let symbol: String
    public let status: String
    public let defaultVisibility: Bool?
    public let defaultOrdinalLevel: Int?
    public let contractId: String
    public let decimals: Int
}

public struct BlockchainAssetsDTO {
    public let mainInfo: MainBlockchainInfoDTO
    public let childBlockchains: [String: ChildBlockchainDTO]

    public init(mainInfo: MainBlockchainInfoDTO, childBlockchains: [String: ChildBlockchainDTO]) {
        self.mainInfo = mainInfo
        self.childBlockchains = childBlockchains
    }
}
extension BlockchainAssetsDTO {
    public static var assets: [BlockchainAssetsDTO] = {
        var assets = [BlockchainAssetsDTO]()
        let jsonDataArray = AssetManager.loadFilesFromBlockchainsEthereum()
        
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
