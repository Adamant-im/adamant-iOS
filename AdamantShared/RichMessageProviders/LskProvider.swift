//
//  LskProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class LskProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "lsk_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "lsk_notificationContent", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "LSK"
    }
    
    override var currencyLogoLarge: UIImage {
        return #imageLiteral(resourceName: "lisk_notification")
    }
}
