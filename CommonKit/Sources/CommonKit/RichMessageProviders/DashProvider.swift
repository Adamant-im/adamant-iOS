//
//  DashProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/08/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class DashProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "dash_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "dash_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "DASH"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "dash_notification") ?? .init()
    }
}
