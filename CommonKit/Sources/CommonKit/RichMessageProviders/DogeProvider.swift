//
//  DogeProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class DogeProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "doge_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "doge_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "DOGE"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "doge_notification") ?? .init()
    }
}
