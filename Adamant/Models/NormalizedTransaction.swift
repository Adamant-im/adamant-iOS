//
//  NormalizedTransaction.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct NormalizedTransaction {
	let type: TransactionType
	let amount: UInt
	let senderPublicKey: String
	let requesterPublicKey: String?
	let timestamp: UInt
	let recipientId: String
	
	var date: Date {
		return AdamantUtilities.decodeAdamantDate(timestamp: TimeInterval(timestamp))
	}
}

extension NormalizedTransaction: Decodable {
	enum CodingKeys: String, CodingKey {
		case type
		case amount
		case senderPublicKey
		case requesterPublicKey
		case timestamp
		case recipientId
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.type = try container.decode(TransactionType.self, forKey: .type)
		self.amount = try container.decode(UInt.self, forKey: .amount)
		self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
		self.requesterPublicKey = try? container.decode(String.self, forKey: .requesterPublicKey)
		self.timestamp = try container.decode(UInt.self, forKey: .timestamp)
		self.recipientId = try container.decode(String.self, forKey: .recipientId)
	}
}

extension NormalizedTransaction: WrappableModel {
	static let ModelKey = "transaction"
}

// MARK: - JSON
/*
{
	"success": true,
	"transaction": {
		"type": 0,
		"amount": 50505050505,
		"senderPublicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
		"requesterPublicKey": null,
		"timestamp": 11236791,
		"asset": {
		},
		"recipientId": "U2279741505997340299"
	}
}
*/
