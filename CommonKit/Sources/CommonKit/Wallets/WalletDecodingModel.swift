//
//  WalletDecodingModel.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 6.1.25..
//
import Foundation

struct WalletDecodingModel: Decodable {
    let name: String
    let nameShort: String?
    let website: String?
    let description: String?
    let explorer: String?
    let explorerTx: String?
    let explorerAddress: String?
    let explorerContract: String?
    let regexAddress: String?
    let research: String?
    let symbol: String
    let type: String
    let decimals: Int
    let cryptoTransferDecimals: Int
    let minBalance: Decimal?
    let minTransferAmount: Decimal?
    let fixedFee: Decimal?
    let defaultFee: Decimal?
    let qqPrefix: String?
    let status: String
    let createCoin: Bool
    let defaultVisibility: Bool?
    let defaultOrdinalLevel: Int?
    let consensus: String?
    let blockTimeFixed: Int?
    let blockTimeAvg: Int?
    let walletNodes: WalletNodes?
    let services: [String: Service]?
    let links: [Link]?
    let tor: Tor?

    enum CodingKeys: String, CodingKey {
        case name
        case nameShort
        case website
        case description
        case explorer
        case explorerTx
        case explorerAddress
        case explorerContract
        case regexAddress
        case research
        case symbol
        case type
        case decimals
        case cryptoTransferDecimals
        case minBalance
        case minTransferAmount
        case fixedFee
        case defaultFee
        case qqPrefix
        case status
        case createCoin
        case defaultVisibility
        case defaultOrdinalLevel
        case consensus
        case blockTimeFixed
        case blockTimeAvg
        case walletNodes = "nodes"
        case services
        case links
        case tor
    }
}

struct WalletNodes: Decodable {
    let list: [WalletNode]
    let healthCheck: WalletHealthCheck?
    let minVersion: String?
}

struct WalletNode: Decodable {
    let url: String
    let altIP: String?

    enum CodingKeys: String, CodingKey {
        case url
        case altIP = "alt_ip"
    }
}

struct WalletHealthCheck: Decodable {
    let normalUpdateInterval: Int
    let crucialUpdateInterval: Int
    let onScreenUpdateInterval: Int
    let threshold: Int?
}

struct Service: Decodable {
    let description: ServiceDescription?
    let list: [ServiceNode]
    let healthCheck: WalletHealthCheck?
    let minVersion: String?
}

struct ServiceDescription: Decodable {
    let software: String?
    let github: String?
    let docs: String?
}

struct ServiceNode: Decodable {
    let url: String
    let altIP: String?

    enum CodingKeys: String, CodingKey {
        case url
        case altIP = "alt_ip"
    }
}

struct Link: Decodable {
    let name: String
    let url: String
}

struct Tor: Decodable {
    let website: String?
    let explorer: String?
    let explorerTx: String?
    let explorerAddress: String?
    let walletNodes: WalletNodes?
    let services: [String: Service]?
    let links: [Link]?
}
extension WalletNodes {
    func toNodes() -> [Node] {
        return list.map { walletNode in
            Node.makeDefaultNode(
                url: URL(string: walletNode.url)!,
                altUrl: walletNode.altIP.flatMap { URL(string: $0) }
            )
        }
    }
}
