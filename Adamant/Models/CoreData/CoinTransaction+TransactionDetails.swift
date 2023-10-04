//
//  CoinTransaction+TransactionDetails.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 04.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation


extension CoinTransaction: TransactionDetails {
    var defaultCurrencySymbol: String? { AdmWalletService.currencySymbol }

    var senderAddress: String {
        senderId ?? ""
    }
    
    var recipientAddress: String {
        recipientId ?? ""
    }
    
    var dateValue: Date? {
        date as? Date
    }
    
    var amountValue: Decimal? {
        amount?.decimalValue
    }
    
    var feeValue: Decimal? { fee?.decimalValue }
    
    var confirmationsValue: String? { return isConfirmed ? String(confirmations) : nil }
    
    var blockValue: String? { return isConfirmed ? blockId : nil }
    
    var txId: String { return transactionId }
    
    var blockHeight: UInt64? {
        return nil
    }
}
