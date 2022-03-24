//
//  TransactionModel.swift
//  Lisk
//
//  Created by Andrew Barba on 1/2/18.
//

import Foundation

extension Transactions {
    
    public struct TransactionSubmitModel: APIModel {
        public let transactionId: String

        // MARK: - Hashable

        public static func == (lhs: TransactionSubmitModel, rhs: TransactionSubmitModel) -> Bool {
            return lhs.transactionId == rhs.transactionId
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(transactionId)
        }
    }

    public struct TransactionModel: APIModel {

        public let id: String

        public let height: UInt64

        public let blockId: String

        public let type: UInt8

        public let timestamp: UInt32

        public let senderPublicKey: String

        public let senderId: String

        public let recipientId: String?

        public let recipientPublicKey: String?

        public let amount: String

        public let fee: String

        public let signature: String

        public var confirmations: UInt64?

        // MARK: - Hashable

        public static func == (lhs: TransactionModel, rhs: TransactionModel) -> Bool {
            return lhs.id == rhs.id
        }

        public var hashValue: Int {
            return id.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public mutating func updateConfirmations(value: UInt64){
            confirmations = value
        }
    }
}
