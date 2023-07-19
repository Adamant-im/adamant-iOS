//
//  AdamantProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class AdamantProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "adm_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "adm_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "ADM"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "adamant_notification") ?? .init()
    }
}
