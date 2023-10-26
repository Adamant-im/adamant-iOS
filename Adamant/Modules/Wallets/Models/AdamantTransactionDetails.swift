//
//  AdamantTransactionDetails.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol AdamantTransactionDetails: TransactionDetails {
    /// The identifier of the transaction.
    var txId: String { get }
    
    /// The sender of the transaction.
    var senderAddress: String { get }
    
    /// The reciver of the transaction.
    var recipientAddress: String { get }
    
    /// The date the transaction was sent.
    var dateValue: Date? { get }
    
    /// The amount of currency that was sent.
    var amountValue: Decimal? { get }
    
    /// The amount of fee that taken for transaction process.
    var feeValue: Decimal? { get }
    
    /// The confirmations of the transaction.
    var confirmationsValue: String? { get }
    
    var blockHeight: UInt64? { get }
    
    /// The block of the transaction.
    var blockValue: String? { get }
    
    var isOutgoing: Bool { get }
    
    var transactionStatus: TransactionStatus? { get }
    
    var defaultCurrencySymbol: String? { get }
    
    var feeCurrencySymbol: String? { get }
    
    func summary(
        with url: String?,
        currentValue: String?,
        valueAtTimeTxn: String?
    ) -> String
    
    var partnerName: String? { get }
    
    var comment: String? { get }
    
    var showToChat: Bool? { get }
    
    var chatRoom: Chatroom? { get }
}
