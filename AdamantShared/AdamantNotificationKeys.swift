//
//  AdamantNotificationKeys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

struct AdamantNotificationCategories {
    static let message = "message"
    static let transfer = "transfer"
    
    private init() {}
}

struct AdamantNotificationUserInfoKeys {
    /// Transaction Id. Transaction that fired the push
    static let transactionId = "txn-id"
    
    /// Address, registered for pushes
    static let pushRecipient = "push-recipient"
    
    /// Partner(sender) display name
    static let partnerDisplayName = "partner.displayName"
    
    // Chache flag, that display name were checked, and partner has none - no need to ckeck again
    static let partnerNoDislpayNameKey = "partner.noDisplayName"
    static let partnerNoDisplayNameValue = "true"
    
    /// Downloaded by NotificationServiceExtension transaction, serialized in JSON format
    static let transaction = "cache.transaction"
    
    /// Decoded message, if push was handled locally by NotificationServiceExtension
    /// Use this to save time on downloading transaction, loading Core and decoding message
    static let decodedMessage = "cache.decoded-message"
    
    private init() {}
}
