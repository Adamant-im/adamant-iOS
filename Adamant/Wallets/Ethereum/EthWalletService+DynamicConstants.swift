import Foundation
import BigInt
    
extension EthWalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = 0.0
    static let currencySymbol = "ETH"
    static let currencyExponent: Int = -18
    static let qqPrefix: String = "ethereum"
    
    var reliabilityGasPricePercent: BigUInt {
        10
    }
        
    var reliabilityGasLimitPercent: BigUInt {
        10
    }
        
    var defaultGasPriceGwei: BigUInt {
        30
    }
        
    var defaultGasLimit: BigUInt {
        22000
    }
        
    var warningGasPriceGwei: BigUInt {
        70
    }
        
    var tokenName: String {
        "Ethereum"
    }
    
    var consistencyMaxTime: Double {
        1200
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
        20
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
