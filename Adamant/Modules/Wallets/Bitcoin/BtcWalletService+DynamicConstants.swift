import Foundation
import BigInt
import CommonKit
    
extension BtcWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 3.153e-05
    static let currencySymbol = "BTC"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "bitcoin"
    
    static var newPendingInterval: Int {
        10000
    }
        
    static var oldPendingInterval: Int {
        3000
    }
        
    static var registeredInterval: Int {
        40000
    }
        
    static var newPendingAttempts: Int {
        20
    }
        
    static var oldPendingAttempts: Int {
        4
    }
        
    var tokenName: String {
        "Bitcoin"
    }
    
    var consistencyMaxTime: Double {
        10800
    }
    
    var minBalance: Decimal {
        1.0e-05
    }
    
    var minAmount: Decimal {
        5.46e-06
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        10
    }
    
    static let explorerAddress = "https://explorer.btc.com/btc/transaction/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://btcnode1.adamant.im")!),
Node(url: URL(string: "https://btcnode2.adamant.im")!),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
