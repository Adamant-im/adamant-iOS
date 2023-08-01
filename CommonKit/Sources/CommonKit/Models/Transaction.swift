//
//  Transaction.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct Transaction {
    public let id: UInt64
    public let height: Int64
    public let blockId: String
    public let type: TransactionType
    public let timestamp: UInt64
    public let senderPublicKey: String
    public let senderId: String
    public let requesterPublicKey: String?
    public let recipientId: String
    public let recipientPublicKey: String?
    public let amount: Decimal
    public let fee: Decimal
    public let signature: String
    public let signSignature: String?
    public let confirmations: Int64
    public let signatures: [String]
    public let asset: TransactionAsset
    
    public let date: Date // Calculated from timestamp
}

extension Transaction: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case height
        case blockId
        case type
        case timestamp
        case senderPublicKey
        case senderId
        case requesterPublicKey
        case recipientId
        case recipientPublicKey
        case amount
        case fee
        case signature
        case signSignature
        case confirmations
        case signatures
        case asset
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UInt64(try container.decode(String.self, forKey: .id))!
        self.height = (try? container.decode(Int64.self, forKey: .height)) ?? 0
        self.blockId = (try? container.decode(String.self, forKey: .blockId)) ?? ""
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        self.senderPublicKey = try container.decode(String.self, forKey: .senderPublicKey)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.recipientId = (try? container.decode(String.self, forKey: .recipientId)) ?? ""
        self.recipientPublicKey = try? container.decode(String.self, forKey: .recipientPublicKey)
        self.signature = (try? container.decode(String.self, forKey: .signature)) ?? ""
        self.confirmations = (try? container.decode(Int64.self, forKey: .confirmations)) ?? 0
        self.requesterPublicKey = try? container.decode(String.self, forKey: .requesterPublicKey)
        self.signSignature = try? container.decode(String.self, forKey: .signSignature)
        self.signatures = (try? container.decode([String].self, forKey: .signatures)) ?? []
        self.asset = try container.decode(TransactionAsset.self, forKey: .asset)
        
        let amount = try container.decode(Decimal.self, forKey: .amount)
        self.amount = amount.shiftedFromAdamant()
        
        let fee = try container.decode(Decimal.self, forKey: .fee)
        self.fee = fee.shiftedFromAdamant()

        self.date = AdamantUtilities.decodeAdamant(timestamp: TimeInterval(self.timestamp))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(String(id), forKey: .id) // String
        try container.encode(height, forKey: .height) // UInt64
        try container.encode(blockId, forKey: .blockId) // String
        try container.encode(type, forKey: .type) // TransactionType
        try container.encode(timestamp, forKey: .timestamp) // UInt64
        try container.encode(senderPublicKey, forKey: .senderPublicKey) // String
        try container.encode(senderId, forKey: .senderId) // String
        try container.encode(recipientId, forKey: .recipientId) // String?
        try container.encode(recipientPublicKey, forKey: .recipientPublicKey) // String
        try container.encode(signature, forKey: .signature) // String
        try container.encode(requesterPublicKey, forKey: .requesterPublicKey) // String?
        try container.encode(signatures, forKey: .signatures) // [String]
        try container.encode(asset, forKey: .asset) // TransactionAsset
        try container.encode(signSignature, forKey: .signSignature) // String?
        try container.encode(confirmations > .zero ? confirmations : nil, forKey: .confirmations)
        
        try container.encode(amount.shiftedToAdamant(), forKey: .amount) // Decimal
        try container.encode(fee.shiftedToAdamant(), forKey: .fee) // Decimal
    }
    
}

extension Transaction: WrappableModel {
    public static let ModelKey = "transaction"
}

extension Transaction: WrappableCollection {
    public static let CollectionKey = "transactions"
}

// MARK: - JSON
/* Fund transfers
{
    "id": "",
    "height": 0,
    "blockId": "",
    "type": 0,
    "timestamp": 0,
    "senderPublicKey": "",
    "senderId": "",
    "recipientId": "",
    "recipientPublicKey": "",
    "amount": 0,
    "fee": 0,
    "signature": "",
    "signatures": [
    ],
    "confirmations": 0,
    "asset": {
    }
}
*/

/* Chat messages
{
    "id": "",
    "height": 0,
    "blockId": "",
    "type": 8,
    "timestamp": 0,
    "senderPublicKey": "",
    "requesterPublicKey": null,
    "senderId": "",
    "recipientId": "",
    "recipientPublicKey": null,
    "amount": 0,
    "fee": 500000,
    "signature": "",
    "signSignature": null,
    "signatures": [
    ],
    "confirmations": null,
    "asset": {
        "chat": {
            "message": "",
            "own_message": "",
            "type": 0
        }
    }
}
*/

/* State transaction
{
    "id": "",
    "height": 0,
    "blockId": "",
    "type": 9,
    "timestamp": 22645079,
    "senderPublicKey": "",
    "requesterPublicKey": null,
    "senderId": "",
    "recipientId": null,
    "recipientPublicKey": null,
    "amount": 0,
    "fee": 100000,
    "signature": "",
    "signSignature": null,
    "signatures": [
    ],
    "confirmations": null,
    "asset": {
    "state": {
        "value": "0",
        "key": "eth:address",
        "type": 0
    }
}
*/
