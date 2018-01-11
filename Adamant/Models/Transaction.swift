//
//  Transaction.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Transaction {
	let id: UInt
	let height: UInt
	let blockId: UInt
	let type: TransactionType
	let timestamp: UInt
	let date: Date	// Calculated from timeinterval
	let senderPublicKey: String
	let senderId: String
	let recipientId: String
	let recipientPublicKey: String
	let amount: UInt
	let fee: UInt
	let signature: String
	let confirmations: UInt
	
	// let signatures: [Any]
	// let asset: Any?

	init(id: UInt, height: UInt, blockId: UInt, type: TransactionType, timestamp: UInt, senderPublicKey: String, senderId: String, recipientId: String, recipientPublicKey: String, amount: UInt, fee: UInt, signature: String, confirmations: UInt) {
		self.id = id
		self.height = height
		self.blockId = blockId
		self.type = type
		self.timestamp = timestamp
		self.senderPublicKey = senderPublicKey
		self.senderId = senderId
		self.recipientId = recipientId
		self.recipientPublicKey = recipientPublicKey
		self.amount = amount
		self.fee = fee
		self.signature = signature
		self.confirmations = confirmations
		
		self.date = AdamantUtilities.decodeAdamantDate(timestamp: TimeInterval(self.timestamp))
	}
}

extension Transaction: Decodable {
	enum CodingKeys: String, CodingKey {
		case id
		case height
		case blockId
		case type
		case timestamp
		case senderPublicKey
		case senderId
		case recipientId
		case recipientPublicKey
		case amount
		case fee
		case signature
		case confirmations
		case signatures
		case asset
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.id = UInt(try container.decode(String.self, forKey: .id))!
		self.height = try container.decode(UInt.self, forKey: .height)
		self.blockId = UInt(try container.decode(String.self, forKey: .blockId))!
		self.type = try container.decode(TransactionType.self, forKey: .type)
		self.timestamp = try container.decode(UInt.self, forKey: .timestamp)
		self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
		self.senderId = try container.decode(String.self, forKey: .senderId)
		self.recipientId = try container.decode(String.self, forKey: .recipientId)
		self.recipientPublicKey = try container.decode(String.self, forKey: .recipientPublicKey)
		self.amount = try container.decode(UInt.self, forKey: .amount)
		self.fee = try container.decode(UInt.self, forKey: .fee)
		self.signature = try container.decode(String.self, forKey: .signature)
		self.confirmations = try container.decode(UInt.self, forKey: .confirmations)
		
		self.date = AdamantUtilities.decodeAdamantDate(timestamp: TimeInterval(self.timestamp))
	}
}

extension Transaction: WrappableCollection {
	static let CollectionKey = "transactions"
}

//extension Array where Transaction {
//	static let Key = "transactions"
//}

// MARK: - JSON
/*
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
