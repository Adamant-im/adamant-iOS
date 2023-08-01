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
public enum ChatType: Hashable {
    case unknown(raw: Int)
    case messageOld        // 0
    case message        // 1
    case richMessage    // 2
    case signal            // 3
    
    public init(from int: Int) {
        self = int.toChatType()
    }
    
    public var rawValue: Int {
        switch self {
        case .messageOld: return 0
        case .message: return 1
        case .richMessage: return 2
        case .signal: return 3
            
        case .unknown(let raw): return raw
        }
    }
}

extension ChatType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let type = try container.decode(Int.self)
        
        self = type.toChatType()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ChatType: Equatable {
    public static func == (lhs: ChatType, rhs: ChatType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

private extension Int {
    func toChatType() -> ChatType {
        switch self {
        case 0: return .messageOld
        case 1: return .message
        case 2: return .richMessage
        case 3: return .signal
        default: return .unknown(raw: self)
        }
    }
}
