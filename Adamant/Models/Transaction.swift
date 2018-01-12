//
//  Transaction.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Transaction: Codable {
	let id: UInt
	let height: UInt
	let blockId: UInt
	let type: TransactionType
	let timestamp: UInt
	let senderPublicKey: String
	let senderId: String
	let recipientId: String
	let recipientPublicKey: String?
	let amount: UInt
	let fee: UInt
	let signature: String
	let signSignature: String?
	let confirmations: UInt?
	let signatures: [String]?
	let asset: TransactionAsset
	
	var date: Date {
		return AdamantUtilities.decodeAdamantDate(timestamp: TimeInterval(self.timestamp))
	}
}

extension Transaction: WrappableCollection {
	static let CollectionKey = "transactions"
}


// MARK: - JSON
/* Fund transfers
{
	"id": "",
	"height": 0,
	"blockId": "",
	"type": 0,
	"timestamp": 0,
	"senderPublicKey": "",
	"senderId": "",
	"recipientId": "",
	"recipientPublicKey": "",
	"amount": 0,
	"fee": 0,
	"signature": "",
	"signatures": [
	],
	"confirmations": 0,
	"asset": {
	}
}
*/

/* Chat messages
{
	"id": "",
	"height": 0,
	"blockId": "",
	"type": 8,
	"timestamp": 0,
	"senderPublicKey": "",
	"requesterPublicKey": null,
	"senderId": "",
	"recipientId": "",
	"recipientPublicKey": null,
	"amount": 0,
	"fee": 500000,
	"signature": "",
	"signSignature": null,
	"signatures": [
	],
	"confirmations": null,
	"asset": {
		"chat": {
			"message": "",
			"own_message": "",
			"type": 0
		}
	}
}
*/
