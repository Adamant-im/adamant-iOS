//
//  EthTransactionRichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct EthTransactionRichMessage {
	static let defaultType = "eth_transaction"
	
	let type: String
	let amount: Decimal
	let hash: String
	let comments: String?
}

extension EthTransactionRichMessage: Encodable, Decodable {
	enum CodingKeys: String, CodingKey {
		case type, amount, hash, comments
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type, forKey: .type)
		try container.encode(AdamantBalanceFormat.full.format(balance: amount), forKey: .amount)
		try container.encode(hash, forKey: .hash)
		
		if let comments = comments {
			try container.encode(comments, forKey: .comments)
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.type = try container.decode(String.self, forKey: .type)
		self.hash = try container.decode(String.self, forKey: .hash)
		self.comments = try? container.decode(String.self, forKey: .comments)
		
		let amountRaw = try container.decode(String.self, forKey: .amount)
		self.amount =  Decimal(string: amountRaw)!
	}
}
