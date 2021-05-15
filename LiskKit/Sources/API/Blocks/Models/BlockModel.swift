//
//  BlockModel.swift
//  Lisk
//
//  Created by Andrew Barba on 1/9/18.
//

import Foundation

extension Blocks {

    public struct BlockModel: APIModel {

        public let id: String

        public let version: Int?

        public let height: Int

        public let timestamp: Int

        public let generatorAddress: String?

        public let generatorPublicKey: String

        public let payloadLength: Int?

        public let payloadHash: String?

        public let blockSignature: String?

        public let confirmations: Int?

        public let previousBlockId: String?

        public let numberOfTransactions: Int

        public let totalAmount: String

        public let totalFee: String

        public let reward: String

        public let totalForged: String

        // MARK: - Hashable

        public static func == (lhs: BlockModel, rhs: BlockModel) -> Bool {
            return lhs.id == rhs.id
        }

        public var hashValue: Int {
            return id.hashValue
        }
    }
}
