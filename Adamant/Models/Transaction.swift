//
//  Transaction.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Transaction {
	let id: UInt
	let height: Int
	let blockId: UInt
	let type: TransactionType
	let timestamp: UInt
	let senderPublicKey: String
	let senderId: String
	let requesterPublicKey: String?
	let recipientId: String
	let recipientPublicKey: String?
	let amount: UInt
	let fee: UInt
	let signature: String
	let signSignature: String?
	let confirmations: UInt
	let signatures: [String]
	let asset: TransactionAsset
	
	let date: Date // Calculated from timestamp
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
		case requesterPublicKey
		case recipientId
		case recipientPublicKey
		case amount
		case fee
		case signature
		case signSignature
		case confirmations
		case signatures
		case asset
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.id = UInt(try container.decode(String.self, forKey: .id))!
		self.height = try container.decode(Int.self, forKey: .height)
		self.blockId = UInt(try container.decode(String.self, forKey: .blockId))!
		self.type = try container.decode(TransactionType.self, forKey: .type)
		self.timestamp = try container.decode(UInt.self, forKey: .timestamp)
		self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
		self.senderId = try container.decode(String.self, forKey: .senderId)
		self.recipientId = try container.decode(String.self, forKey: .recipientId)
		self.recipientPublicKey = try? container.decode(String.self, forKey: .recipientPublicKey)
		self.amount = try container.decode(UInt.self, forKey: .amount)
		self.fee = try container.decode(UInt.self, forKey: .fee)
		self.signature = try container.decode(String.self, forKey: .signature)
		self.confirmations = (try? container.decode(UInt.self, forKey: .confirmations)) ?? 0
		self.requesterPublicKey = try? container.decode(String.self, forKey: .requesterPublicKey)
		self.signSignature = try? container.decode(String.self, forKey: .signSignature)
		self.signatures = try container.decode([String].self, forKey: .signatures)
		self.asset = try container.decode(TransactionAsset.self, forKey: .asset)

		self.date = AdamantUtilities.decodeAdamantDate(timestamp: TimeInterval(self.timestamp))
	}
}

extension Transaction: WrappableModel {
	static let ModelKey = "transaction"
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
