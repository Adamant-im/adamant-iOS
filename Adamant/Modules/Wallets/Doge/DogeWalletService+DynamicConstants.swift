import Foundation
import BigInt
import CommonKit
    
extension DogeWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 1
    static let currencySymbol = "DOGE"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "doge"
    
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 390,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 3,
        normalServiceUpdateInterval: 390,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
        
    static var newPendingInterval: Int {
        5000
    }
        
    static var oldPendingInterval: Int {
        3000
    }
        
    static var registeredInterval: Int {
        20000
    }
        
    static var newPendingAttempts: Int {
        20
    }
        
    static var oldPendingAttempts: Int {
        4
    }
        
    var tokenName: String {
        "Dogecoin"
    }
    
    var consistencyMaxTime: Double {
        900
    }
    
    var minBalance: Decimal {
        0
    }
    
    var minAmount: Decimal {
        1
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        70
    }
    
    static var minNodeVersion: String? {
        nil
    }
    
    var transferDecimals: Int {
        8
    }
    
    static let explorerAddress = "https://dogechain.info/tx/"
    
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://dogenode1.adamant.im")!, altUrl: URL(string: "http://5.9.99.62:44099")),
Node.makeDefaultNode(url: URL(string: "https://dogenode2.adamant.im")!, altUrl: URL(string: "http://176.9.32.126:44098")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
