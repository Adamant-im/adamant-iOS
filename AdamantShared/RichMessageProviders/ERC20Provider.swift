//
//  ERC20Provider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05.07.2020.
//  Copyright © 2020 Adamant. All rights reserved.
//

import UIKit

class ERC20Provider: TransferBaseProvider {
    override class var richMessageType: String {
        return "erc20_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "wallet_\(token.symbol.lowercased())", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return token.symbol
    }
    
    override var currencyLogoLarge: UIImage {
        return token.logo
    }
    
    private let token: ERC20Token

    init(_ token: ERC20Token) {
        self.token = token
    }
}
