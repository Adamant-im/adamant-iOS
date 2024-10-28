//
//  TransactionDetailsProtocol.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

/// A standard protocol representing a Transaction details.
protocol TransactionDetails: Sendable {
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
    
    var nonceRaw: String? { get }
    
    var txBlockchainComment: String? { get }
    
    func summary(
        with url: String?,
        currentValue: String?,
        valueAtTimeTxn: String?
    ) -> String
}

extension TransactionDetails {
    var feeCurrencySymbol: String? { defaultCurrencySymbol }
    
    var txBlockchainComment: String? { nil }
    
    func summary(
        with url: String? = nil,
        currentValue: String? = nil,
        valueAtTimeTxn: String? = nil
    ) -> String {
        let symbol = self.defaultCurrencySymbol
        
        var summary = """
        Transaction \(txId)
        
        Summary
        Sender: \(senderAddress)
        Recipient: \(recipientAddress)
        Amount: \(AdamantBalanceFormat.full.format(amountValue ?? 0, withCurrencySymbol: symbol))
        """
        
        if let fee = feeValue {
            summary += "\nFee: \(AdamantBalanceFormat.full.format(fee, withCurrencySymbol: feeCurrencySymbol))"
        }
        
        if let date = dateValue {
            let dateString = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .medium)
            summary += "\nDate: \(dateString)"
        }
        
        if let confirmations = confirmationsValue {
            summary += "\nConfirmations: \(confirmations)"
        }
        
        if let block = blockValue {
            summary += "\nBlock: \(block)"
        }
        
        if let status = transactionStatus {
            summary += "\nStatus: \(status.localized)"
        }
        
        if let value = currentValue {
            summary += "\nCurrent value: \(value)"
        }
        
        if let value = valueAtTimeTxn {
            summary += "\nValue at time of Txn: \(value)"
        }
        
        if let url = url {
            summary += "\nURL: \(url)"
        }
        
        return summary
    }
}
