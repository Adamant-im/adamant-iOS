//
//  AdamantExportTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantExportTools {
	static func summaryFor(transaction: Transaction, url: URL) -> String {
		return """
Transaction #\(String(transaction.id))

Summary
Sender: \(transaction.senderId)
Recipient: \(transaction.recipientId)
Date: \(DateFormatter.localizedString(from: transaction.date, dateStyle: .short, timeStyle: .medium))
Amount: \(AdamantUtilities.format(balance: transaction.amount))
Fee: \(AdamantUtilities.format(balance: transaction.fee))
Confirmations: \(String(transaction.confirmations))
Block: \(transaction.blockId)
URL: \(url)
"""
	}
	
	private init() {}
}
