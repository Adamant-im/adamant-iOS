//
//  EthProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class EthProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "eth_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "eth_notification", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "ETH"
    }
    
    override var currencyLogo: UIImage {
        return #imageLiteral(resourceName: "wallet_eth")
    }
}
