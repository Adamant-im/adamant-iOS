//
//  DogeProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class DogeProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "doge_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "doge_notification", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "DOGE"
    }
}
