import Foundation

extension DogeWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 1
    static let currencySymbol = "DOGE"
    static let currencyExponent: Int = -8
    
    var consistencyMaxTime: Double {
        900
    }
    
    static var minBalance: Decimal {
        0
    }
    
    static var minAmount: Decimal {
        0
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