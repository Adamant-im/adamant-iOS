//
//  LskProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class KlyProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "kly_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "klayr_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "KLY"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "klayr_notification") ?? .init()
    }
}
