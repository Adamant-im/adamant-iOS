//
//  ERC20Provider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05.07.2020.
//  Copyright © 2020 Adamant. All rights reserved.
//

import UIKit

public final class ERC20Provider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "erc20_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "\(token.symbol.lowercased())_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return token.symbol
    }
    
    public override var currencyLogoLarge: UIImage {
        return token.logo
    }
    
    private let token: ERC20Token

    public init(_ token: ERC20Token) {
        self.token = token
    }
}
