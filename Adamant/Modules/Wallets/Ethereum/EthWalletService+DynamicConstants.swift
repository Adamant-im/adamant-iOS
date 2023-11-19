import Foundation
import BigInt
import CommonKit
    
extension EthWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0
    static let currencySymbol = "ETH"
    static let currencyExponent: Int = -18
    static let qqPrefix: String = "ethereum"
    
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
        30
    }
        
    var defaultGasLimit: BigUInt {
        22000
    }
        
    var warningGasPriceGwei: BigUInt {
        70
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
    
    var minNodeVersion: String? {
        nil
    }
    
    static let explorerAddress = "https://etherscan.io/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://ethnode1.adamant.im")!, altUrl: URL(string: "http://95.216.41.106:44099")),
Node(url: URL(string: "https://ethnode2.adamant.im")!, altUrl: URL(string: "http://95.216.114.252:44099")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
