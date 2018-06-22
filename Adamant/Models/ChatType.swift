//
//  ChatType.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// - messageExpensive: Old message type, with 0.005 transaction fee
/// - message: new and main message type, with 0.001 transaction fee
/// - richMessage: json with additional data
/// - signal: hidden system message for/from services
enum ChatType: Codable {
	case unknown(raw: Int16)
	case messageOld // 0
	case message // 1
	case richMessage // 2
	case signal // 3
	
	init(from int16: Int16) {
		switch int16 {
		case 0: self = .messageOld
		case 1: self = .message
		case 2: self = .richMessage
		case 3: self = .signal
			
		default: self = .unknown(raw: int16)
		}
	}
	
	var rawValue: Int16 {
		switch self {
		case .messageOld: return 0
		case .message: return 1
		case .richMessage: return 2
		case .signal: return 3
			
		case .unknown(let raw): return raw
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let type = try container.decode(Int16.self)
		
		self.init(from: type)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}
