//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct RichMessageType {
	let stringValue: String
}

protocol RichMessage: Codable {
	var type: RichMessageType { get }
	
	func serialized() -> String
}

extension RichMessage {
	func serialized() -> String {
		if let data = try? JSONEncoder().encode(self), let raw = String(data: data, encoding: String.Encoding.utf8) {
			return raw
		} else {
			return ""
		}
	}
}

struct RichMessageTransfer: RichMessage {
	let type: RichMessageType
	let amount: Decimal
	let hash: String
	let comments: String
}

extension RichMessageTransfer {
	enum CodingKeys: String, CodingKey {
		case type, amount, hash, comments
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type.stringValue, forKey: .type)
		try container.encode(amount, forKey: .amount)
		try container.encode(hash, forKey: .hash)
		try container.encode(comments, forKey: .comments)
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let typeRaw = try container.decode(String.self, forKey: .type)
		self.type = RichMessageType(stringValue: typeRaw)
		self.amount = try container.decode(Decimal.self, forKey: .amount)
		self.hash = try container.decode(String.self, forKey: .hash)
		self.comments = try container.decode(String.self, forKey: .comments)
	}
}
