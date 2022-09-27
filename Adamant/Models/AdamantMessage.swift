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
    case richMessage(payload: RichMessage)
}

// MARK: - Fee
extension AdamantMessage {
    static private let textFee = Decimal(sign: .plus, exponent: -3, significand: 1)
    
    var fee: Decimal {
        switch self {
        case .text(let message), .markdownText(let message):
            return AdamantMessage.feeFor(text: message)
            
        case .richMessage(let payload):
            return AdamantMessage.feeFor(text: payload.serialized())
        }
    }
    
    private static func feeFor(text: String) -> Decimal {
        return Decimal(ceil(Double(text.count) / 255.0)) * AdamantMessage.textFee
    }
}

// MARK: - ChatType
extension AdamantMessage {
    var chatType: ChatType {
        switch self {
        case .text, .markdownText:
            return .message
            
        case .richMessage:
            return .richMessage
        }
    }
}
