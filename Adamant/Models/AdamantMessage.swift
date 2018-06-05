//
//  AdamantMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// Adamant message types
///
/// - text: Simple text message
/// - markdownText: attributed text, formatted with markdown
enum AdamantMessage {
	case text(String)
	case markdownText(String)
}

extension AdamantMessage {
	static private let textFee = Decimal(sign: .plus, exponent: -3, significand: 1)
	
	var fee: Decimal {
		switch self {
		case .text(let message), .markdownText(let message):
			return Decimal(ceil(Double(message.count) / 255.0)) * AdamantMessage.textFee
		}
	}
}
