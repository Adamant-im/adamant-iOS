import Foundation
import BigInt
import CommonKit
    
extension AdmWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.5
    static let currencySymbol = "ADM"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "adm"
    
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 300,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 10,
        normalServiceUpdateInterval: 300,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
        
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
    
    static var minNodeVersion: String? {
        "0.8.0"
    }
    
    var transferDecimals: Int {
        8
    }
    
    static let explorerAddress = "https://explorer.adamant.im/tx/"
    
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://clown.adamant.im")!),
Node.makeDefaultNode(url: URL(string: "https://lake.adamant.im")!),
Node.makeDefaultNode(url: URL(string: "https://endless.adamant.im")!, altUrl: URL(string: "http://149.102.157.15:36666")),
Node.makeDefaultNode(url: URL(string: "https://bid.adamant.im")!),
Node.makeDefaultNode(url: URL(string: "https://unusual.adamant.im")!),
Node.makeDefaultNode(url: URL(string: "https://debate.adamant.im")!, altUrl: URL(string: "http://95.216.161.113:36666")),
Node.makeDefaultNode(url: URL(string: "http://78.47.205.206:36666")!),
Node.makeDefaultNode(url: URL(string: "http://5.161.53.74:36666")!),
Node.makeDefaultNode(url: URL(string: "http://184.94.215.92:45555")!),
Node.makeDefaultNode(url: URL(string: "https://node1.adamant.business")!, altUrl: URL(string: "http://194.233.75.29:45555")),
Node.makeDefaultNode(url: URL(string: "https://node2.blockchain2fa.io")!),
Node.makeDefaultNode(url: URL(string: "https://phecda.adm.im")!, altUrl: URL(string: "http://46.250.234.248:36666")),
Node.makeDefaultNode(url: URL(string: "https://tegmine.adm.im")!),
Node.makeDefaultNode(url: URL(string: "https://tauri.adm.im")!, altUrl: URL(string: "http://154.26.159.245:36666")),
Node.makeDefaultNode(url: URL(string: "https://dschubba.adm.im")!),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://info.adamant.im")!),
Node.makeDefaultNode(url: URL(string: "https://info2.adm.im")!),
        ]
    }
}
