//
//  ServiceTransactionModel.swift
//  
//
//  Created by Anton Boyarkin on 15.08.2021.
//

import Foundation

public enum ExecutionStatus: String, Decodable {
    case pending
    case successful
    case failed
    case unknown
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawValue = try? container.decode(String.self),
           let status = ExecutionStatus(rawValue: rawValue) {
            self = status
        } else {
            self = .unknown
        }
    }
}

public struct ServiceTransactionModel: APIModel {
    
    public var blockId: String? {
        return block?.id
    }
    
    public var type: UInt8 {
        return 0
    }
    
    public var timestamp: UInt32? {
        return block?.timestamp
    }
    
    public var senderPublicKey: String {
        return sender.publicKey
    }
    
    public var senderId: String {
        return sender.address
    }
    
    public var recipientId: String {
        return params.recipientAddress
    }
    
    public var recipientPublicKey: String? {
        return nil
    }
    
    public var amount: String {
        return params.amount
    }
    
    public var signature: String {
        return ""
    }
    
    public var confirmations: UInt64 {
        return 0
    }
    
    public var height: UInt64? {
        block?.height
    }
    
    public struct Block: APIModel {
        public let id: String
        public let height: UInt64
        public let timestamp: UInt32
    }
    
    public struct Sender: APIModel {
        public let address: String
        public let publicKey: String
    }
    
    public struct Params: APIModel {
        public let amount: String
        public let recipientAddress: String
    }

    public let id: String
    public let fee: String
    public let block: Block?
    public let sender: Sender
    public let params: Params
    public let executionStatus: ExecutionStatus
    public let nonce: String
    
    // MARK: - Hashable

    public static func == (lhs: ServiceTransactionModel, rhs: ServiceTransactionModel) -> Bool {
        return lhs.id == rhs.id
    }

    public var hashValue: Int {
        return id.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
