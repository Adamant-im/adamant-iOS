//
//  DogeTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class DogeTransaction: TransactionDetails {
    var txId: String = ""
    var senderAddress: String = ""
    var recipientAddress: String = ""
    var dateValue: Date?
    var amountValue: Decimal = 0
    var feeValue: Decimal?
    var confirmationsValue: String?
    var blockValue: String? = nil
    var isOutgoing: Bool = false
    var transactionStatus: TransactionStatus?
    
    static func from(_ dictionry: [String: Any], with walletAddress: String) -> DogeTransaction  {
        let transaction = DogeTransaction()
        
        if let txid = dictionry["txid"] as? String { transaction.txId = txid }
        if let vin = dictionry["vin"] as? [[String: Any]], let input = vin.first, let address = input["addr"] as? String {
            transaction.senderAddress = address
            if address == walletAddress {
                transaction.isOutgoing = true
            }
        }
        if let vout = dictionry["vout"] as? [[String: Any]] {
            let outputs = vout.filter { item -> Bool in
                if let publickKey = item["scriptPubKey"] as? [String: Any], let addresses = publickKey["addresses"] as? [String], let address = addresses.first {
                    if transaction.isOutgoing, address != walletAddress {
                        return true
                    } else if !transaction.isOutgoing, address == walletAddress {
                        return true
                    }
                }
                return false
            }
            if let output = outputs.first, let publickKey = output["scriptPubKey"] as? [String: Any], let addresses = publickKey["addresses"] as? [String], let address = addresses.first, let valueRaw = output["value"] as? String, let value = Decimal(string: valueRaw) {
                transaction.recipientAddress = address
                transaction.amountValue = value
            }
        }
        if let time = dictionry["time"] as? NSNumber { transaction.dateValue = Date(timeIntervalSince1970: time.doubleValue) }
        if let fees = dictionry["fees"] as? NSNumber { transaction.feeValue = fees.decimalValue }
        if let confirmations = dictionry["confirmations"] as? NSNumber { transaction.confirmationsValue = confirmations.stringValue }
        if let blockhash = dictionry["blockhash"] as? String { transaction.blockValue = blockhash }
        
        transaction.transactionStatus = TransactionStatus.success
        
        return transaction
    }
}
