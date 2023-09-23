//
//  EthProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public final class EthProvider: TransferBaseProvider {
    public override class var richMessageType: String {
        return "eth_transaction"
    }
    
    public override var currencyLogoUrl: URL? {
        return Bundle.main.url(forResource: "eth_notificationContent", withExtension: "png")
    }
    
    public override var currencySymbol: String {
        return "ETH"
    }
    
    public override var currencyLogoLarge: UIImage {
        return .asset(named: "ethereum_notification") ?? .init()
    }
}
