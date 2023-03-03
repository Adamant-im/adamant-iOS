import Foundation
import BigInt
    
extension DogeWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 1
    static let currencySymbol = "DOGE"
    static let currencyExponent: Int = -8
    static let qqPrefix: String = "doge"
    
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
        0
    }
    
    var defaultVisibility: Bool {
        true
    }
    
    var defaultOrdinalLevel: Int? {
        40
    }
    
    static let explorerAddress = "https://dogechain.info/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://dogenode1.adamant.im")!),
Node(url: URL(string: "https://dogenode2.adamant.im")!),
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}
