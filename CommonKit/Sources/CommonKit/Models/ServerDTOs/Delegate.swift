//
//  Delegate.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public final class Delegate: Decodable {
    public let username: String
    public let address: String
    public let publicKey: String
    public let voteObsolete: String
    public let voteFair: String
    public let producedblocks: Int
    public let missedblocks: Int
    public let rate: Int
    public let rank: Int
    public let approval: Double
    public let productivity: Double
    
    public var voted: Bool = false
    
    public enum CodingKeys: String, CodingKey {
        case username
        case address
        case publicKey
        case voteObsolete = "vote"
        case voteFair = "votesWeight"
        case producedblocks
        case missedblocks
        case rate
        case rank
        case approval
        case productivity
    }
    
    public init(
        username: String,
        address: String,
        publicKey: String,
        voteObsolete: String,
        voteFair: String,
        producedblocks: Int,
        missedblocks: Int,
        rate: Int,
        rank: Int,
        approval: Double,
        productivity: Double,
        voted: Bool
    ) {
        self.username = username
        self.address = address
        self.publicKey = publicKey
        self.voteObsolete = voteObsolete
        self.voteFair = voteFair
        self.producedblocks = producedblocks
        self.missedblocks = missedblocks
        self.rate = rate
        self.rank = rank
        self.approval = approval
        self.productivity = productivity
        self.voted = voted
    }
}

extension Delegate: WrappableModel {
    public static let ModelKey = "delegate"
}

extension Delegate: WrappableCollection {
    public static let CollectionKey = "delegates"
}

public struct DelegateForgeDetails: Decodable, Sendable {
    public let nodeTimestamp: Date
    public let fees: Decimal
    public let rewards: Decimal
    public let forged: Decimal
    
    public enum CodingKeys: String, CodingKey {
        case nodeTimestamp
        case fees
        case rewards
        case forged
    }
    
    public init(from decoder: Decoder) throws {
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

public struct DelegatesCountResult: Decodable, Sendable {
    public let nodeTimestamp: UInt64
    public let count: UInt
}

public struct NextForgersResult: Decodable, Sendable {
    public let nodeTimestamp: Date
    public let currentBlock: UInt64
    public let currentBlockSlot: UInt64
    public let currentSlot: UInt64
    public let delegates: [String]
    
    public enum CodingKeys: String, CodingKey {
        case nodeTimestamp
        case currentBlock
        case currentBlockSlot
        case currentSlot
        case delegates
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.currentBlock = try container.decode(UInt64.self, forKey: .currentBlock)
        self.currentBlockSlot = try container.decode(UInt64.self, forKey: .currentBlockSlot)
        self.currentSlot = try container.decode(UInt64.self, forKey: .currentSlot)
        self.delegates = try container.decode([String].self, forKey: .delegates)
        
        let timestamp = try container.decode(UInt64.self, forKey: .nodeTimestamp)
        self.nodeTimestamp = AdamantUtilities.decodeAdamant(timestamp: TimeInterval(timestamp))
    }
}

public struct Block: Decodable {
    public let id: String
    public let version: UInt
    public let timestamp: UInt64
    public let height: UInt64
    public let previousBlock:String
    public let numberOfTransactions: UInt
    public let totalAmount: UInt
    public let totalFee: UInt
    public let reward: UInt
    public let payloadLength: UInt
    public let payloadHash: String
    public let generatorPublicKey: String
    public let generatorId: String
    public let blockSignature: String
    public let confirmations: UInt
    public let totalForged: String
}

extension Block: WrappableModel {
    public static let ModelKey = "block"
}

extension Block: WrappableCollection {
    public static let CollectionKey = "blocks"
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
