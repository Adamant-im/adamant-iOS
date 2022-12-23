import Foundation

extension ERC20Token {
    static let supportedTokens: [ERC20Token] = [

        ERC20Token(symbol: "BNB",
                   name: "Binance Coin",
                   contractAddress: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
                   decimals: 18,
                   naturalUnits: 18),
        ERC20Token(symbol: "USDS",
                   name: "Stably USD",
                   contractAddress: "0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe",
                   decimals: 6,
                   naturalUnits: 6),
    ]
    
}
