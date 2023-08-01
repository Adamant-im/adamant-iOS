//
//  BtcProvider.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit

public final class BtcProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "btc_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "btc_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "BTC"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "bitcoin_notification") ?? .init()
    }
}
