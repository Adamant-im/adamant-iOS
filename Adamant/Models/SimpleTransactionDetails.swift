//
//  SimpleTransactionDetails.swift
//  Adamant
//
//  Created by Anokhov Pavel on 26.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct SimpleTransactionDetails: TransactionDetails {
    static var defaultCurrencySymbol: String? { return nil }
    
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
}
