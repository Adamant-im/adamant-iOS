//
//  RichMessageNotificationProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import UserNotifications

struct NotificationContent {
    let title: String
    let subtitle: String?
    let body: String
    let attachments: [UNNotificationAttachment]?
}

protocol RichMessageNotificationProvider {
    static var richMessageType: String { get }
    
    func notificationContent(for transaction: Transaction, partner: String, richContent: [String:String]) -> NotificationContent?
}
