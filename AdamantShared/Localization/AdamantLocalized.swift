//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    public struct adamantLocalized {
        private init() { }
        
        struct notifications {
            static let error = NSLocalizedString("NotificationContent.error", tableName: "notificationContent", comment: "Notification content: error working with transaction")
            
            static func error(with message: String) -> String {
                return String.localizedStringWithFormat(NSLocalizedString("NotificationContent.errorFormat", tableName: "notificationContent", comment: "Notification content: error format"), message)
            }
            
            private init() {}
        }
    }
}

