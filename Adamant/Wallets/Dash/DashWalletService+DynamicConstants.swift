import Foundation

extension DashWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0001
    static let currencySymbol = "DASH"
    static let currencyExponent: Int = -8
    
    var consistencyMaxTime: Double {
        800
    }
    
    static var minBalance: Decimal {
        0.0001
    }
    
    static var minAmount: Decimal {
        2.0e-05
    }
    
    static let explorerAddress = "https://dashblockexplorer.com/tx/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://dashnode1.adamant.im")!),

        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}