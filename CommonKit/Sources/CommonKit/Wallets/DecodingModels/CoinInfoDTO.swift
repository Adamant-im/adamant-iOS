//
//  CoinInfoDTO.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 13.1.25..
//
import Foundation
import AdamantWalletsAssets

public struct CoinInfoDTO: Decodable {
    public let name: String
    public let nameShort: String?
    public let website: String?
    public let description: String?
    public let explorer: String?
    public let explorerTx: String?
    public let explorerAddress: String?
    public let regexAddress: String?
    public let symbol: String
    public let type: String
    public let decimals: Int
    public let cryptoTransferDecimals: Int
    public let minBalance: Decimal?
    public let minTransferAmount: Double?
    public let fixedFee: Decimal?
    public let defaultFee: Decimal?
    public let qqPrefix: String?
    public let status: String
    public let createCoin: Bool
    public let defaultVisibility: Bool?
    public let defaultOrdinalLevel: Int?
    public let consensus: String?
    public let blockTimeFixed: Int?
    public let reliabilityGasPricePercent: Int?
    public let reliabilityGasLimitPercent: Int?
    public let defaultGasPriceGwei: Int?
    public let defaultGasLimit: Int?
    public let warningGasPriceGwei: Int?
    public let blockTimeAvg: Int?
    public let nodes: Nodes?
    public let services: Services?
    public let links: [Link]?
    public let tor: Tor?
    public let txFetchInfo: TxFetchInfo?
    public let timeout: Timeout?

    public struct Node: Decodable {
        public let url: String
        public let altIP: String?
    }

    public struct NodeHealthCheck: Decodable {
        public let normalUpdateInterval: Int
        public let crucialUpdateInterval: Int
        public let onScreenUpdateInterval: Int
        public let threshold: Int?
    }

    public struct Service: Decodable {
        let description: Description
        public let list: [Node]
        public let healthCheck: NodeHealthCheck?
        let minVersion: String?
    }
    
    public struct Description: Decodable {
        let software: String
        let github: String
        let docs: String?
    }

    public struct Services: Decodable {
        public let infoService: Service?
        public let ipfsNode: Service?
    }

    public struct Tor: Decodable {
        let website: String?
        let explorer: String?
        let explorerTx: String?
        let explorerAddress: String?
        let nodes: Nodes?
        let services: Services?
    }

    public struct Nodes: Decodable {
        public let list: [Node]
        public let healthCheck: NodeHealthCheck
        public let minVersion: String?
    }

    public struct TxFetchInfo: Decodable {
        public let newPendingInterval: Int
        public let oldPendingInterval: Int
        public let registeredInterval: Int
        public let newPendingAttempts: Int?
        public let oldPendingAttempts: Int?
    }

    public struct Timeout: Decodable {
        let message: Int
        let attachment: Int
    }

    public struct Link: Decodable {
        let name: String
        let url: String
    }
}

extension CoinInfoDTO {
    public static var coins: [String: CoinInfoDTO] {
        return cachedCoinInfo
    }

    private static var cachedCoinInfo: [String: CoinInfoDTO] = {
        let jsonDataArray = AssetManager.loadFilesFromGeneral()
        var decodedData = [String: CoinInfoDTO]()
        
        let decoder = JSONDecoder()
        for data in jsonDataArray {
            do {
                let coinInfo = try decoder.decode(CoinInfoDTO.self, from: data)
                decodedData[coinInfo.symbol] = coinInfo
            } catch {
                print("Failed to decode CoinInfoDTO: \(error)")
            }
        }
        return decodedData
    }()
}
