//
//  MainBlockchainInfoDTO.swift
//  AdamantWalletsKit
//
//  Created by Владимир Клевцов on 17.1.25..
//


import Foundation
import AdamantWalletsAssets

public struct MainBlockchainInfoDTO: Codable {
    public let blockchain: String
    public let type: String
    public let mainCoin: String
    public let fees: String
    public let defaultGasLimit: Int
}

public struct ChildBlockchainDTO: Codable {
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
