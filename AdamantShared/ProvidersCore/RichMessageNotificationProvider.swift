//
//  RichMessageNotificationProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

protocol RichMessageNotificationProvider {
    static var richMessageType: String { get }
    
    func notificationContent(for transaction: Transaction, partnerAddress: String, partnerName: String?, richContent: [String: Any]) -> NotificationContent?
}

protocol TransferNotificationContentProvider: RichMessageNotificationProvider {
    var currencyLogoLarge: UIImage { get }
    var currencySymbol: String { get }
}
