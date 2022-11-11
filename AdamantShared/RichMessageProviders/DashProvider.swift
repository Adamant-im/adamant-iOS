//
//  DashProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/08/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class DashProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "dash_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "dash_notificationContent", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "DASH"
    }
    
    override var currencyLogoLarge: UIImage {
        return #imageLiteral(resourceName: "wallet_dash")
    }
}
