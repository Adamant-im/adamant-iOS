//
//  NodeStatusModel.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

extension Node {

    public struct NodeStatusModel: APIModel {

        public let broadhash: String

        public let consensus: Int

        public let height: Int

        public let loaded: Bool

        public let networkHeight: Int

        public let syncing: Bool

        public let transactions: NodeStatusTransactionsModel
    }

    public struct NodeStatusTransactionsModel: APIModel {

        public let unconfirmed: Int

        public let unsigned: Int

        public let unprocessed: Int

        public let confirmed: Int

        public let total: Int
    }
}
