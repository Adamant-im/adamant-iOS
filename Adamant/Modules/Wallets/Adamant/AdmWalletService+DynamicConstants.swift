import Foundation
import BigInt
import CommonKit
    
extension AdmWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.5
    static let currencySymbol = "ADM"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "adm"
    
    static var newPendingInterval: Int {
        4000
    }
        
    static var oldPendingInterval: Int {
        4000
    }
        
    static var registeredInterval: Int {
        4000
    }
        
    var tokenName: String {
        "ADAMANT Messenger"
    }
    
    var consistencyMaxTime: Double {
        0
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
        0
    }
    
    static let explorerAddress = "https://explorer.adamant.im/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://clown.adamant.im")!),
Node(url: URL(string: "https://lake.adamant.im")!),
Node(url: URL(string: "https://endless.adamant.im")!),
Node(url: URL(string: "https://bid.adamant.im")!),
Node(url: URL(string: "https://unusual.adamant.im")!),
Node(url: URL(string: "https://debate.adamant.im")!),
Node(url: URL(string: "http://78.47.205.206:36666")!),
Node(url: URL(string: "http://5.161.53.74:36666")!),
Node(url: URL(string: "http://184.94.215.92:45555")!),
Node(url: URL(string: "https://node1.adamant.business")!),
Node(url: URL(string: "https://node2.blockchain2fa.io")!),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}