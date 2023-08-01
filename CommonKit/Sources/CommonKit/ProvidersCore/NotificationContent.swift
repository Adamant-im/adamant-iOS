//
//  NotificationContent.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UserNotifications

public struct NotificationContent {
    public let title: String
    public let subtitle: String?
    public let body: String
    public let attachments: [UNNotificationAttachment]?
    public let categoryIdentifier: String?
    
    public init(
        title: String,
        subtitle: String?,
        body: String,
        attachments: [UNNotificationAttachment]?,
        categoryIdentifier: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.attachments = attachments
        self.categoryIdentifier = categoryIdentifier
    }
}
