import Foundation
import BigInt
import CommonKit
    
extension EthWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0
    static let currencySymbol = "ETH"
    static let currencyExponent: Int = -18
    static let qqPrefix: String = "ethereum"
    
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 300,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 5,
        normalServiceUpdateInterval: 300,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
        
    static var newPendingInterval: Int {
        4000
    }
        
    static var oldPendingInterval: Int {
        3000
    }
        
    static var registeredInterval: Int {
        5000
    }
        
    static var newPendingAttempts: Int {
        20
    }
        
    static var oldPendingAttempts: Int {
        4
    }
        
    var reliabilityGasPricePercent: BigUInt {
        10
    }
        
    var reliabilityGasLimitPercent: BigUInt {
        10
    }
        
    var defaultGasPriceGwei: BigUInt {
        10
    }
        
    var defaultGasLimit: BigUInt {
        22000
    }
        
    var warningGasPriceGwei: BigUInt {
        25
    }
        
    var tokenName: String {
        "Ethereum"
    }
    
    var consistencyMaxTime: Double {
        1200
    }
    
    var minBalance: Decimal {
        0
    }
    
    var minAmount: Decimal {
        0
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        20
    }
    
    static var minNodeVersion: String? {
        nil
    }
    
    var transferDecimals: Int {
        6
    }
    
    static let explorerAddress = "https://etherscan.io/tx/"
    
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://ethnode2.adamant.im")!, altUrl: URL(string: "http://95.216.114.252:44099")),
Node.makeDefaultNode(url: URL(string: "https://ethnode3.adamant.im")!, altUrl: URL(string: "http://46.4.37.157:44099")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
