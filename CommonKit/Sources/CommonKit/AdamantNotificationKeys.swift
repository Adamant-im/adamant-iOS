//
//  AdamantNotificationKeys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public enum AdamantNotificationCategories {
    public static let message = "message"
    public static let transfer = "transfer"
}

public enum AdamantNotificationUserInfoKeys {
    /// Transaction Id. Transaction that fired the push
    public static let transactionId = "txn-id"
    
    /// Address, registered for pushes
    public static let pushRecipient = "push-recipient"
    
    /// Partner(sender) display name
    public static let partnerDisplayName = "partner.displayName"
    
    // Chache flag, that display name were checked, and partner has none - no need to ckeck again
    public static let partnerNoDislpayNameKey = "partner.noDisplayName"
    public static let partnerNoDisplayNameValue = "true"
    
    /// Downloaded by NotificationServiceExtension transaction, serialized in JSON format
    public static let transaction = "cache.transaction"
    
    /// Decoded message, if push was handled locally by NotificationServiceExtension
    /// Use this to save time on downloading transaction, loading Core and decoding message
    public static let decodedMessage = "cache.decoded-message"
}
