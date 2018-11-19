//
//  AdamantFormattingTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension String.adamantLocalized.chat {
	static let sent = NSLocalizedString("ChatScene.Sent", comment: "Chat: 'Sent funds' bubble title")
	static let tapForDetails = NSLocalizedString("ChatScene.tapForDetails", comment: "Chat: 'Sent funds' buble 'Tap for details' tip")
}

class AdamantFormattingTools {
	static func summaryFor(transaction: Transaction, url: URL?) -> String {
		return summaryFor(id: String(transaction.id),
                          sender: transaction.senderId,
                          recipient: transaction.recipientId,
                          date: transaction.date,
                          amount: transaction.amount,
                          fee: transaction.fee,
                          confirmations: String(transaction.confirmations),
                          blockId: transaction.blockId,
                          url: url)
	}
    
    static func summaryFor(transaction: TransactionDetails, url: URL?) -> String {
        return summaryFor(id: transaction.id ?? "",
                          sender: transaction.senderAddress,
                          recipient: transaction.recipientAddress,
                          date: transaction.dateValue,
                          amount: transaction.amountValue,
                          fee: transaction.feeValue ?? 0,
                          confirmations: transaction.confirmationsValue,
                          blockId: transaction.blockValue,
                          url: url)
    }
	
	private static func summaryFor(id: String, sender: String, recipient: String, date: Date?, amount: Decimal, fee: Decimal, confirmations: String?, blockId: String?, url: URL?) -> String {
		
        var summary = """
Transaction #\(id)

Summary
Sender: \(sender)
Recipient: \(recipient)
Amount: \(AdamantUtilities.format(balance: amount))
Fee: \(AdamantUtilities.format(balance: fee))
"""
        
        if let date = date {
            summary = summary + "Date: \(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .medium))"
        }
        
        if let confirmations = confirmations {
            summary = summary + "Confirmations: \(confirmations)"
        }
        
        if let blockId = blockId {
            summary = summary + "\nBlock: \(blockId)"
        }
        
        if let url = url {
            summary = summary + "\nURL: \(url)"
        }
        
        return summary
	}
	
	private init() {}
}
