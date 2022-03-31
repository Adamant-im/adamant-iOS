//
//  TransactionDetailsProtocol.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// A standard protocol representing a Transaction details.
protocol TransactionDetails {
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
    
    static var defaultCurrencySymbol: String? { get }
    func summary(with url: String?) -> String
}

extension TransactionDetails {
    func summary(with url: String? = nil) -> String {
        let symbol = type(of: self).defaultCurrencySymbol
        
        var summary = """
        Transaction \(txId)
        
        Summary
        Sender: \(senderAddress)
        Recipient: \(recipientAddress)
        Amount: \(AdamantBalanceFormat.full.format(amountValue ?? 0, withCurrencySymbol: symbol))
        """
        
        if let fee = feeValue {
            summary += "\nFee: \(AdamantBalanceFormat.full.format(fee, withCurrencySymbol: symbol))"
        }
        
        if let date = dateValue {
            summary += "\nDate: \(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .medium))"
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
        
        if let url = url {
            summary += "\nURL: \(url)"
        }
        
        return summary
    }
}
