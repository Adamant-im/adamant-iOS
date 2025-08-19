import Foundation

public struct CoinInfoDTO: Codable {
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
    public let increasedGasPricePercent: Int?
    public let defaultGasPriceGwei: Int?
    public let defaultGasLimit: Int?
    public let warningGasPriceGwei: Int?
    public let blockTimeAvg: Int?
    public let balanceCheckInterval: Int?
    public let balanceCheckIntervalNewAccount: Int? // Only for ADM
    public let balanceValidInterval: Int?
    public let nodes: Nodes?
    public let services: Services?
    public let links: [Link]?
    public let txFetchInfo: TxFetchInfo?
    public let timeout: Timeout?
    public let contractId: String?
    public let txConsistencyMaxTime: Int?

    public struct Node: Codable {
        public enum CodingKeys: String, CodingKey {
            case url
            case altIp = "alt_ip"
        }
        
        public let url: String
        public let altIp: String?
    }

    public struct NodeHealthCheck: Codable {
        public let normalUpdateInterval: Int
        public let crucialUpdateInterval: Int
        public let onScreenUpdateInterval: Int
        public let threshold: Int?
    }

    public struct Description: Codable {
        let software: String
        let github: String
        let docs: String?
    }

    public struct Service: Codable {
        let description: Description
        public let list: [Node]
        public let healthCheck: NodeHealthCheck?
        let minVersion: String?
    }

    public struct Services: Codable {
        public let infoService: Service?
        public let ipfsNode: Service?
    }

    public struct Nodes: Codable {
        public let list: [Node]
        public let healthCheck: NodeHealthCheck
        public let minVersion: String?
    }

    public struct TxFetchInfo: Codable {
        public let newPendingInterval: Int
        public let oldPendingInterval: Int
        public let registeredInterval: Int
        public let newPendingAttempts: Int?
        public let oldPendingAttempts: Int?
    }

    public struct Timeout: Codable {
        let message: Int
        let attachment: Int
    }

    public struct Link: Codable {
        let name: String
        let url: String
    }
}
