//
//  LskProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class LskProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "lsk_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "lsk_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "LSK"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "lisk_notification") ?? .init()
    }
}
