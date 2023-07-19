//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    enum adamant {
        public enum notifications {
            // MARK: - Content extensions error
            
            public static let error = String.localized(
                "content.error",
                comment: "Notification content: error working with transaction"
            )
            
            public static func error(with message: String) -> String {
                String.localizedStringWithFormat(
                    String.localized(
                        "content.error.format",
                        comment: "Notification content: error format"
                    ),
                    message
                )
            }
            
            // MARK: - Transfer preview
            
            public static let newTransfer = String.localized(
                "transfer.notificationTitle",
                comment: "New transfer notification title"
            )
            
            public static func yourTransferBody(with amount: String) -> String {
                String.localizedStringWithFormat(
                    String.localized(
                        "transfer.notificationBody.format",
                        comment: "Transfer notification body format"
                    ),
                    amount
                )
            }
            
            public static let yourAddress = String.localized(
                "transfer.notificationBody.yourAddress",
                comment: "Transfer notification: 'Your address'"
            )
        }
    }
    
    static func localized(_ key: String, comment: String = .empty) -> String {
        NSLocalizedString(key, bundle: .module, comment: comment)
    }
}
