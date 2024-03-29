//
//  SimpleTransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 26.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct SimpleTransactionDetails: AdamantTransactionDetails, Hashable {
    var defaultCurrencySymbol: String?
    
    var txId: String
    
    var senderAddress: String
    
    var recipientAddress: String
    
    var dateValue: Date?
    
    var amountValue: Decimal?
    
    var feeValue: Decimal?
    
    var confirmationsValue: String?
    
    var blockValue: String?
    
    var isOutgoing: Bool
    
    var transactionStatus: TransactionStatus?
    
    var blockHeight: UInt64? {
        return nil
    }
    
    var partnerName: String?
    var comment: String?
    var showToChat: Bool?
    var chatRoom: Chatroom?
    
    var nonceRaw: String?
    
    init(
        defaultCurrencySymbol: String? = nil,
        txId: String,
        senderAddress: String,
        recipientAddress: String,
        dateValue: Date? = nil,
        amountValue: Decimal? = nil,
        feeValue: Decimal? = nil,
        confirmationsValue: String? = nil,
        blockValue: String? = nil,
        isOutgoing: Bool,
        transactionStatus: TransactionStatus? = nil,
        partnerName: String? = nil,
        nonceRaw: String?
    ) {
        self.defaultCurrencySymbol = defaultCurrencySymbol
        self.txId = txId
        self.senderAddress = senderAddress
        self.recipientAddress = recipientAddress
        self.dateValue = dateValue
        self.amountValue = amountValue
        self.feeValue = feeValue
        self.confirmationsValue = confirmationsValue
        self.blockValue = blockValue
        self.isOutgoing = isOutgoing
        self.transactionStatus = transactionStatus
        self.partnerName = partnerName
        self.nonceRaw = nonceRaw
    }
    
    init(_ transaction: TransactionDetails) {
        self.defaultCurrencySymbol = transaction.defaultCurrencySymbol
        self.txId = transaction.txId
        self.senderAddress = transaction.senderAddress
        self.recipientAddress = transaction.recipientAddress
        self.dateValue = transaction.dateValue
        self.amountValue = transaction.amountValue
        self.feeValue = transaction.feeValue
        self.confirmationsValue = transaction.confirmationsValue
        self.blockValue = transaction.blockValue
        self.isOutgoing = transaction.isOutgoing
        self.transactionStatus = transaction.transactionStatus
        self.nonceRaw = transaction.nonceRaw
    }
    
    init(_ transaction: TransferTransaction) {
        self.defaultCurrencySymbol = transaction.defaultCurrencySymbol
        self.txId = transaction.txId
        self.senderAddress = transaction.senderAddress
        self.recipientAddress = transaction.recipientAddress
        self.dateValue = transaction.dateValue
        self.amountValue = transaction.amountValue
        self.feeValue = transaction.feeValue
        self.confirmationsValue = transaction.confirmationsValue
        self.blockValue = transaction.blockValue
        self.isOutgoing = transaction.isOutgoing
        self.transactionStatus = transaction.transactionStatus
        self.showToChat = transaction.showToChat
        self.chatRoom = transaction.chatRoom
        self.partnerName = transaction.partnerName
        self.comment = transaction.comment
        self.transactionStatus = transaction.transactionStatus
    }
}
