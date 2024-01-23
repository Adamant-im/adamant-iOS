import Foundation
import BigInt
import CommonKit
    
extension DashWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0001
    static let currencySymbol = "DASH"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "dash"
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 210,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 3,
        normalServiceUpdateInterval: 210,
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
        30000
    }
        
    static var newPendingAttempts: Int {
        20
    }
        
    static var oldPendingAttempts: Int {
        4
    }
        
    var tokenName: String {
        "Dash"
    }
    
    var consistencyMaxTime: Double {
        800
    }
    
    var minBalance: Decimal {
        0.0001
    }
    
    var minAmount: Decimal {
        2.0e-05
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        80
    }
    
    var minNodeVersion: String? {
        nil
    }
    
    static let explorerAddress = "https://dashblockexplorer.com/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://dashnode1.adamant.im")!, altUrl: URL(string: "http://45.85.147.224:44099")),
Node(url: URL(string: "https://dashnode2.adamant.im")!, altUrl: URL(string: "http://207.180.210.95:44099")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
