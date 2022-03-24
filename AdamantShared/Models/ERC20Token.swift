//
//  ERC20Token.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

struct ERC20Token {
    let symbol: String
    let name: String
    let contractAddress: String
    let decimals: Int
    let naturalUnits: Int
    var logo: UIImage {
        UIImage(named: "wallet_\(symbol.lowercased())") ?? UIImage()
    }
}

extension ERC20Token {
    static let supportedTokens: [ERC20Token] = [
        ERC20Token(symbol: "BNB",
                   name: "Binance Coin",
                   contractAddress: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
                   decimals: 18,
                   naturalUnits: 18),
        ERC20Token(symbol: "USDS",
                   name: "Stably Dollar",
                   contractAddress: "0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe",
                   decimals: 6,
                   naturalUnits: 6)
//        ERC20Token(symbol: "BZ",
//                   name: "Bit-Z",
//                   contractAddress: "0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063",
//                   decimals: 18,
//                   naturalUnits: 18),
//        ERC20Token(symbol: "KCS",
//                   name: "KuCoin Shares",
//                   contractAddress: "0x039b5649a59967e3e936d7471f9c3700100ee1ab",
//                   decimals: 6,
//                   naturalUnits: 6),
//        ERC20Token(symbol: "RES",
//                   name: "Resfinex Token",
//                   contractAddress: "0x0a9f693fce6f00a51a8e0db4351b5a8078b4242e",
//                   decimals: 5,
//                   naturalUnits: 5)//, добавить токен
        // Test ERC20 Tokens in Ropsten testnet
//        ERC20Token(symbol: "BOKKY", name: "BOKKY", contractAddress: "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367", decimals: 18, logo: #imageLiteral(resourceName: "wallet_kcs")),
//        ERC20Token(symbol: "WEENUS", name: "WEENUS", contractAddress: "0x101848D5C5bBca18E6b4431eEdF6B95E9ADF82FA", decimals: 18, logo: #imageLiteral(resourceName: "wallet_usds"))
    ]
}
