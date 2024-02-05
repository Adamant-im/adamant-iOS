import Foundation
import BigInt
import CommonKit
    
extension LskWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.00164
    static let currencySymbol = "LSK"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "lisk"
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 270,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 5,
        normalServiceUpdateInterval: 330,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
        
    static var newPendingInterval: Int {
        3000
    }
        
    static var oldPendingInterval: Int {
        3000
    }
        
    static var registeredInterval: Int {
        5000
    }
        
    static var newPendingAttempts: Int {
        15
    }
        
    static var oldPendingAttempts: Int {
        4
    }
        
    var tokenName: String {
        "Lisk"
    }
    
    var consistencyMaxTime: Double {
        60
    }
    
    var minBalance: Decimal {
        0.05
    }
    
    var minAmount: Decimal {
        0
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        60
    }
    
    static var minNodeVersion: String? {
        nil
    }
    
    static let explorerAddress = "https://liskscan.com/transaction/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://lisknode3.adamant.im")!, altUrl: URL(string: "http://157.90.229.236:44099")),
Node(url: URL(string: "https://lisknode4.adamant.im")!, altUrl: URL(string: "http://78.47.205.206:44099")),
Node(url: URL(string: "https://lisknode5.adamant.im")!, altUrl: URL(string: "http://38.242.243.29:44099")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            Node(url: URL(string: "https://liskservice3.adamant.im")!),
Node(url: URL(string: "https://liskservice4.adamant.im")!),
Node(url: URL(string: "https://liskservice5.adamant.im")!),
        ]
    }
}
