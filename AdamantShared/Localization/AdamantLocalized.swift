//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    struct adamantLocalized {
        private init() { }
        
        struct notifications {
            // MARK: - Content extensions error
            
            static let error = NSLocalizedString("content.error", tableName: "notificationContent", comment: "Notification content: error working with transaction")
            
            static func error(with message: String) -> String {
                return String.localizedStringWithFormat(NSLocalizedString("content.error.format", tableName: "notificationContent", comment: "Notification content: error format"), message)
            }
            
            // MARK: - Transfer preview
            
            static let newTransfer = NSLocalizedString("transfer.notificationTitle", tableName: "notificationContent", comment: "New transfer notification title")
            
            static func yourTransferBody(with amount: String) -> String {
                return String.localizedStringWithFormat(NSLocalizedString("transfer.notificationBody.format", tableName: "notificationContent", comment: "Transfer notification body format"), amount)
            }
            
            static let yourAddress = NSLocalizedString("transfer.notificationBody.yourAddress", tableName: "notificationContent", comment: "Transfer notification: 'Your address'")
            
            static let reacted = NSLocalizedString("ChatListPage.Reacted", comment: "ChatList: Reacted")
            static let removedReaction = NSLocalizedString("ChatListPage.RemovedReaction", comment: "ChatList: Removed Reaction")

            private init() {}
        }
    }
}
