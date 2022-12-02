//
//  BtcProvider.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit

class BtcProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "btc_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "btc_notificationContent", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "BTC"
    }
    
    override var currencyLogoLarge: UIImage {
        return #imageLiteral(resourceName: "bitcoin_notification")
    }
}
