//
//  UnregisteredTransaction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import BigInt

public struct UnregisteredTransaction: Hashable {
    public let type: TransactionType
    public let timestamp: UInt64
    public let senderPublicKey: String
    public let senderId: String
    public let recipientId: String?
    public let amount: Decimal
    public let signature: String
    public let asset: TransactionAsset
    public let requesterPublicKey: String?
    
    public init(
        type: TransactionType,
        timestamp: UInt64,
        senderPublicKey: String,
        senderId: String,
        recipientId: String?,
        amount: Decimal,
        signature: String,
        asset: TransactionAsset,
        requesterPublicKey: String?
    ) {
        self.type = type
        self.timestamp = timestamp
        self.senderPublicKey = senderPublicKey
        self.senderId = senderId
        self.recipientId = recipientId
        self.amount = amount
        self.signature = signature
        self.asset = asset
        self.requesterPublicKey = requesterPublicKey
    }
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
    
    public init(from decoder: Decoder) throws {
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
        self.requesterPublicKey = ""
    }
    
    public func encode(to encoder: Encoder) throws {
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
