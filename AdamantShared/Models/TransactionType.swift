//
//  TransactionType.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum TransactionType {
    case unknown(raw: Int)
    case send        // 0
    case signature    // 1
    case delegate    // 2
    case vote        // 3
    case multi        // 4
    case dapp        // 5
    case inTransfer    // 6
    case outTransfer // 7
    case chatMessage // 8
    case state        // 9
    
    init(from int: Int) {
        self = int.toTransactionType()
    }
    
    var rawValue: Int {
        switch self {
        case .send: return 0
        case .signature: return 1
        case .delegate: return 2
        case .vote: return 3
        case .multi: return 4
        case .dapp: return 5
        case .inTransfer: return 6
        case .outTransfer: return 7
        case .chatMessage: return 8
        case .state: return 9
        
        case .unknown(let raw): return raw
        }
    }
}

extension TransactionType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let type = try container.decode(Int.self)
        self = type.toTransactionType()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension TransactionType: Equatable {
    static func == (lhs: TransactionType, rhs: TransactionType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

fileprivate extension Int {
    func toTransactionType() -> TransactionType {
        switch self {
        case 0: return .send
        case 1: return .signature
        case 2: return .delegate
        case 3: return .vote
        case 4: return .multi
        case 5: return .dapp
        case 6: return .inTransfer
        case 7: return .outTransfer
        case 8: return .chatMessage
        case 9: return .state
        
        default: return .unknown(raw: self)
        }
    }
}
