import Foundation

extension LskWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.00142
    static let currencySymbol = "LSK"
    static let currencyExponent: Int = -8
    
    var consistencyMaxTime: Double {
        60
    }
    
    static var minBalance: Decimal {
        0.05
    }
    
    static var minAmount: Decimal {
        0
    }
    
    static let explorerAddress = "https://liskscan.com/transaction/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://lisknode3.adamant.im")!),
Node(url: URL(string: "https://lisknode4.adamant.im")!),

        ]
    }
    
    static var serviceNodes: [Node] {
        [
            Node(url: URL(string: "https://liskservice3.adamant.im")!),
Node(url: URL(string: "https://liskservice4.adamant.im")!),

        ]
    }
}