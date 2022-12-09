import Foundation

extension EthWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0
    static let currencySymbol = "ETH"
    static let currencyExponent: Int = -18
    
    var consistencyMaxTime: Double {
        1200
    }
    
    static var minBalance: Decimal {
        0
    }
    
    static var minAmount: Decimal {
        0
    }
    
    static let explorerAddress = "https://etherscan.io/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://ethnode1.adamant.im")!),
Node(url: URL(string: "https://ethnode2.adamant.im")!),

        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}