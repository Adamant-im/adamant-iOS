//
//  NormalizedTransaction.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// Used to make a KVC transactions into the blockchain
public struct NormalizedTransaction: SignableTransaction {
    public let type: TransactionType
    public let amount: Decimal
    public let senderPublicKey: String
    public let requesterPublicKey: String?
    public let timestamp: UInt64
    public let recipientId: String?
    public let asset: TransactionAsset
}

public extension NormalizedTransaction {
    init(
        type: TransactionType,
        amount: Decimal,
        senderPublicKey: String,
        requesterPublicKey: String?,
        date: Date,
        recipientId: String?,
        asset: TransactionAsset
    ) {
        self.type = type
        self.amount = amount
        self.senderPublicKey = senderPublicKey
        self.requesterPublicKey = requesterPublicKey
        self.timestamp = UInt64(AdamantUtilities.encodeAdamant(date: date))
        self.recipientId = recipientId
        self.asset = asset
    }
    
    var date: Date {
        return AdamantUtilities.decodeAdamant(timestamp: TimeInterval(timestamp))
    }
}

extension NormalizedTransaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
        case amount
        case senderPublicKey
        case requesterPublicKey
        case timestamp
        case recipientId
        case asset
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
        self.requesterPublicKey = try? container.decode(String.self, forKey: .requesterPublicKey)
        self.timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        self.recipientId = try container.decode(String.self, forKey: .recipientId)
        self.asset = try container.decode(TransactionAsset.self, forKey: .asset)
        
        let amount = try container.decode(Decimal.self, forKey: .amount)
        self.amount = amount.shiftedFromAdamant()
    }
}

extension NormalizedTransaction: WrappableModel {
    public static let ModelKey = "transaction"
}

// MARK: - JSON
/*
{
    "success": true,
    "transaction": {
        "type": 0,
        "amount": 50505050505,
        "senderPublicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
        "requesterPublicKey": null,
        "timestamp": 11236791,
        "asset": {
        },
        "recipientId": "U2279741505997340299"
    }
}
*/
