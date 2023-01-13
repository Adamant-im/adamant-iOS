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
    let defaultVisibility: Bool
    let defaultOrdinalLevel: Int
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
                   naturalUnits: 18,
                   defaultVisibility: true,
                   defaultOrdinalLevel: 60),
        ERC20Token(symbol: "USDS",
                   name: "Stably Dollar",
                   contractAddress: "0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe",
                   decimals: 6,
                   naturalUnits: 6,
                   defaultVisibility: true,
                   defaultOrdinalLevel: 70)
    ]
}
