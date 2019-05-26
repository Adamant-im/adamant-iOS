//
//  AdamantProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class AdamantProvider: TransferBaseProvider {
    override class var richMessageType: String {
        return "adm_transaction"
    }
    
    override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "adm_notification", withExtension: "png")
    }
    
    override var currencySymbol: String {
        return "ADM"
    }
}
