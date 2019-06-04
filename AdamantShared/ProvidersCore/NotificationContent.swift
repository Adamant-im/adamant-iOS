//
//  NotificationContent.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UserNotifications

struct NotificationContent {
    let title: String
    let subtitle: String?
    let body: String
    let attachments: [UNNotificationAttachment]?
    let categoryIdentifier: String?
}
