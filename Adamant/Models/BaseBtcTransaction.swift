//
//  BaseBtcTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class BaseBtcTransaction: TransactionDetails {
    var defaultCurrencySymbol: String? { return "" }
    
    let txId: String
    let dateValue: Date?
    let blockValue: String?
    
    let senderAddress: String
    let recipientAddress: String
    
    let amountValue: Decimal?
    let feeValue: Decimal?
    let confirmationsValue: String?
    
    let isOutgoing: Bool
    let transactionStatus: TransactionStatus?
    
    var blockHeight: UInt64?
    
    required init(txId: String, dateValue: Date?, blockValue: String?, senderAddress: String, recipientAddress: String, amountValue: Decimal, feeValue: Decimal?, confirmationsValue: String?, isOutgoing: Bool, transactionStatus: TransactionStatus?) {
        self.txId = txId
        self.dateValue = dateValue
        self.blockValue = blockValue
        self.senderAddress = senderAddress
        self.recipientAddress = recipientAddress
        self.amountValue = amountValue
        self.feeValue = feeValue
        self.confirmationsValue = confirmationsValue
        self.isOutgoing = isOutgoing
        self.transactionStatus = transactionStatus
        self.blockHeight = nil
    }
}
