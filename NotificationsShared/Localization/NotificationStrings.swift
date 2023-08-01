//
//  NotificationStrings.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

enum NotificationStrings {
    static let registrationRemotesFormat = NSLocalizedString(
        "NotificationsService.Error.RegistrationRemotesFormat",
        comment: "Notifications: Something went wrong while registering remote notifications. %@ for description"
    )
    
    static let newMessageTitle = NSLocalizedString(
        "NotificationsService.NewMessage.Title",
        comment: "Notifications: New message notification title"
    )
    
    static let newMessageBodySingle = NSLocalizedString(
        "Notifications: New single message notification body",
        comment: "Notifications: Something went wrong while registering remote notifications. %@ for description"
    )
    
    static let newTransferTitle = NSLocalizedString(
        "NotificationsService.NewTransfer.Title",
        comment: "Notifications: New transfer transaction title"
    )
    
    static let newTransferBodySingle = NSLocalizedString(
        "NotificationsService.NewTransfer.BodySingle",
        comment: "Notifications: New single transfer transaction body"
    )
    
    static let notificationsDisabled = NSLocalizedString(
        "NotificationsService.NotificationsDisabled",
        comment: "Notifications disabled. You can enable notifications in Settings"
    )
    
    static let notStayedLoggedIn = NSLocalizedString(
        "NotificationsService.NotStayedLoggedIn",
        comment: "Can't turn on notifications without staying logged in"
    )
    
    static func newTransferBody(_ count: Int) -> String {
        .localizedStringWithFormat(
            NSLocalizedString(
                "NotificationsService.NewTransfer.BodyFormat",
                comment: "Notifications: New transfer notification body. Using %d for amount"
            ),
            count
        )
    }
    
    static func newMessageBody(_ count: Int) -> String {
        .localizedStringWithFormat(
            NSLocalizedString(
                "NotificationsService.NewMessage.BodyFormat",
                comment: "Notifications: new messages notification body. Using %d for amount"
            ),
            count
        )
    }
}
