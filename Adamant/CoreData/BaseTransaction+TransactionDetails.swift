//
//  BaseTransaction+TransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension BaseTransaction: TransactionDetails {
    var id: String { return transactionId ?? "" }
    var senderAddress: String { return senderId ?? "" }
    var recipientAddress: String { return self.recipientId ?? "" }
    var blockValue: String? { return self.blockId }
    var confirmationsValue: String? { return String(confirmations) }
    var dateValue: Date? { return date as Date? }
    
    var amountValue: Decimal {
        if let amount = self.amount {
            return amount.decimalValue
        } else {
            return 0
        }
    }
    
    var feeValue: Decimal {
        if let fee = self.fee {
            return fee.decimalValue
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
