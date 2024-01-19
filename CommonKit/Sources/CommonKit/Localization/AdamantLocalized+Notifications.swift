//
//  AdamantLocalized+Notifications.swift
//  
//
//  Created by Andrey Golubenko on 01.08.2023.
//

public extension String.adamant {
    enum notifications {
        // MARK: - Content extensions error
        
        public static var error: String {
            String.localized(
                "content.error",
                comment: "Notification content: error working with transaction"
            )
        }
        
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
        
        public static var newTransfer: String {
            String.localized(
                "transfer.notificationTitle",
                comment: "New transfer notification title"
            )
        }
        
        public static func yourTransferBody(with amount: String) -> String {
            String.localizedStringWithFormat(
                String.localized(
                    "transfer.notificationBody.format",
                    comment: "Transfer notification body format"
                ),
                amount
            )
        }
        
        public static var yourAddress: String {
            String.localized(
                "transfer.notificationBody.yourAddress",
                comment: "Transfer notification: 'Your address'"
            )
        }
    }
}
