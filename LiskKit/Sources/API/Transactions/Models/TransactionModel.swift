//
//  TransactionModel.swift
//  Lisk
//
//  Created by Andrew Barba on 1/2/18.
//

import Foundation

extension Transactions {

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

        public let confirmations: UInt64

        // MARK: - Hashable

        public static func == (lhs: TransactionModel, rhs: TransactionModel) -> Bool {
            return lhs.id == rhs.id
        }

        public var hashValue: Int {
            return id.hashValue
        }
    }
}
