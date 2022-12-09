import Foundation

extension BtcWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 3.153e-05
    static let currencySymbol = "BTC"
    static let currencyExponent: Int = -8
    
    var consistencyMaxTime: Double {
        10800
    }
    
    static var minBalance: Decimal {
        1.0e-05
    }
    
    static var minAmount: Decimal {
        5.46e-06
    }
    
    static let explorerAddress = "https://explorer.btc.com/btc/transaction/"
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "https://btcnode1.adamant.im")!),
Node(url: URL(string: "https://btcnode2.adamant.im")!),

        ]
    }
    
    static var serviceNodes: [Node] {
        [
            
        ]
    }
}