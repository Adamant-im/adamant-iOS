import Foundation
import BigInt
import CommonKit
    
extension KlyWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.00164
    static let currencySymbol = "KLY"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "klayr"
    
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
        "Klayr"
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
        50
    }
    
    static var minNodeVersion: String? {
        nil
    }
    
    var transferDecimals: Int {
        8
    }
    
    static let explorerTx = "https://explorer.klayr.xyz/transaction/"
    static let explorerAddress = "https://explorer.klayr.xyz/account/"
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://klynode2.adamant.im")!, altUrl: URL(string: "http://109.176.199.130:44099")),
Node.makeDefaultNode(url: URL(string: "https://klynode3.adm.im")!, altUrl: URL(string: "http://37.27.205.78:44099")),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            Node.makeDefaultNode(
                url: URL(string: "https://klyservice2.adamant.im")!,
                altUrl: URL(string: "http://109.176.199.130:44098")!
            ),
            Node.makeDefaultNode(
                url: URL(string: "https://klyservice3.adm.im")!,
                altUrl: URL(string: "http://37.27.205.78:44098")!
            ),
        ]
    }
}
