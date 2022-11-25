//
//  UnregisteredTransaction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct UnregisteredTransaction: Hashable {
    let type: TransactionType
    let timestamp: UInt64
    let senderPublicKey: String
    let senderId: String
    let recipientId: String?
    let amount: Decimal
    let signature: String
    let asset: TransactionAsset
}

extension UnregisteredTransaction: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case timestamp
        case senderPublicKey
        case senderId
        case recipientId
        case amount
        case signature
        case asset
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.recipientId = try? container.decode(String.self, forKey: .recipientId)
        self.signature = (try? container.decode(String.self, forKey: .signature)) ?? ""
        self.asset = try container.decode(TransactionAsset.self, forKey: .asset)
        
        let amount = try container.decode(Decimal.self, forKey: .amount)
        self.amount = amount.shiftedFromAdamant()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type) // TransactionType
        try container.encode(timestamp, forKey: .timestamp) // UInt64
        try container.encode(senderPublicKey, forKey: .senderPublicKey) // String
        try container.encode(senderId, forKey: .senderId) // String
        try container.encode(recipientId, forKey: .recipientId) // String?
        try container.encode(signature, forKey: .signature) // String
        try container.encode(asset, forKey: .asset) // TransactionAsset
        try container.encode(amount.shiftedToAdamant(), forKey: .amount) // Decimal
    }
    
}
