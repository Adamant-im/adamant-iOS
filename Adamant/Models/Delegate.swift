//
//  Delegate.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Delegate: Decodable {
    let username: String
    let address: String
    let publicKey: String
    let vote: String
    let producedblocks: Int
    let missedblocks: Int
    let rate: Int
    let rank: Int
    let approval: Double
    let productivity: Double
    
    var voted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case username
        case address
        case publicKey
        case vote
        case producedblocks
        case missedblocks
        case rate
        case rank
        case approval
        case productivity
    }
}

extension Delegate: WrappableModel {
    static let ModelKey = "delegate"
}

extension Delegate: WrappableCollection {
    static let CollectionKey = "delegates"
}

struct DelegateForgeDetails: Decodable {
    let nodeTimestamp: Date
    let fees: Decimal
    let rewards: Decimal
    let forged: Decimal
    
    enum CodingKeys: String, CodingKey {
        case nodeTimestamp
        case fees
        case rewards
        case forged
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let feesStr = try container.decode(String.self, forKey: .fees)
        let fees = Decimal(string: feesStr) ?? 0
        self.fees = fees.shiftedFromAdamant()
        
        let rewardsStr = try container.decode(String.self, forKey: .forged)
        let rewards = Decimal(string: rewardsStr) ?? 0
        self.rewards = rewards.shiftedFromAdamant()
        
        let forgedStr = try container.decode(String.self, forKey: .forged)
        let forged = Decimal(string: forgedStr) ?? 0
        self.forged = forged.shiftedFromAdamant()
        
        let timestamp = try container.decode(UInt64.self, forKey: .nodeTimestamp)
        self.nodeTimestamp = AdamantUtilities.decodeAdamant(timestamp: TimeInterval(timestamp))
    }
}

struct DelegatesCountResult: Decodable {
    let nodeTimestamp: UInt64
    let count: UInt
}

struct NextForgersResult: Decodable {
    let nodeTimestamp: Date
    let currentBlock: UInt64
    let currentBlockSlot: UInt64
    let currentSlot: UInt64
    let delegates: [String]
    
    enum CodingKeys: String, CodingKey {
        case nodeTimestamp
        case currentBlock
        case currentBlockSlot
        case currentSlot
        case delegates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.currentBlock = try container.decode(UInt64.self, forKey: .currentBlock)
        self.currentBlockSlot = try container.decode(UInt64.self, forKey: .currentBlockSlot)
        self.currentSlot = try container.decode(UInt64.self, forKey: .currentSlot)
        self.delegates = try container.decode([String].self, forKey: .delegates)
        
        let timestamp = try container.decode(UInt64.self, forKey: .nodeTimestamp)
        self.nodeTimestamp = AdamantUtilities.decodeAdamant(timestamp: TimeInterval(timestamp))
    }
}

struct Block: Decodable {
    let id: String
    let version: UInt
    let timestamp: UInt64
    let height: UInt64
    let previousBlock:String
    let numberOfTransactions: UInt
    let totalAmount: UInt
    let totalFee: UInt
    let reward: UInt
    let payloadLength: UInt
    let payloadHash: String
    let generatorPublicKey: String
    let generatorId: String
    let blockSignature: String
    let confirmations: UInt
    let totalForged: String
}

extension Block: WrappableModel {
    static let ModelKey = "block"
}

extension Block: WrappableCollection {
    static let CollectionKey = "blocks"
}

/*
{
	"username": "permit",
	"address": "U8339394976025567725",
	"publicKey": "01c5079a2234f69feca1b00daf4ddbd8904e13dfb67ce47c21f26377468706fa",
	"producedblocks": 11153,
	"missedblocks": 3,
	"vote": "13373617430543",
	"votesWeight": "13373617430543",
	"rate": 1,
	"rank": 1,
	"approval": 0.95,
	"productivity": 99.97
}
*/
