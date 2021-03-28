//
//  BaseTransaction+TransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension BaseTransaction: TransactionDetails {
    static var defaultCurrencySymbol: String? { return AdmWalletService.currencySymbol }
    
    var txId: String { return transactionId ?? "" }
    var senderAddress: String { return senderId ?? "" }
    var recipientAddress: String { return recipientId ?? "" }
    var dateValue: Date? { return date as Date? }
    var feeValue: Decimal? { return fee?.decimalValue }
    
    var confirmationsValue: String? { return isConfirmed ? String(confirmations) : nil }
    var blockValue: String? { return isConfirmed ? blockId : nil }
    
    var amountValue: Decimal? {
        if let amount = self.amount {
            return amount.decimalValue
        } else {
            return 0
        }
    }
    
    var block: UInt {
        if let raw = blockId, let id = UInt(raw) {
            return id
        } else {
            return 0
        }
    }
}
