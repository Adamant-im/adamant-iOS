//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - RichMessage

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

struct RichContentKeys {
    static let type = "type"
    
    private init() {}
}


// MARK: - RichMessageTransfer

struct RichMessageTransfer: RichMessage {
	let type: RichMessageType
	let amount: Decimal
	let hash: String
	let comments: String
}

extension RichContentKeys {
    struct transfer {
        static let amount = "amount"
        static let hash = "hash"
        static let comments = "comments"
        
        private init() {}
    }
}

extension RichMessageTransfer {
	private static var formatter: NumberFormatter = {
		let f = NumberFormatter()
		f.numberStyle = .decimal
		f.roundingMode = .floor
		f.decimalSeparator = "."
		f.minimumFractionDigits = 0
		f.maximumFractionDigits = 18
		return f
	}()
	
	enum CodingKeys: String, CodingKey {
		case type, amount, hash, comments
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type.stringValue, forKey: .type)
		try container.encode(hash, forKey: .hash)
		try container.encode(comments, forKey: .comments)
		
		if let amountRaw = RichMessageTransfer.formatter.string(fromDecimal: amount) {
			try container.encode(amountRaw, forKey: .amount)
		} else {
			try container.encode(String(format: "%f", amount as NSNumber), forKey: .amount)
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let typeRaw = try container.decode(String.self, forKey: .type)
		self.type = RichMessageType(stringValue: typeRaw)
		self.hash = try container.decode(String.self, forKey: .hash)
		self.comments = try container.decode(String.self, forKey: .comments)
		
		if let amountRaw = try? container.decode(String.self, forKey: .amount), let amount = RichMessageTransfer.formatter.number(from: amountRaw)?.decimalValue {
			self.amount = amount
		} else {
			self.amount = 0
		}
	}
}
