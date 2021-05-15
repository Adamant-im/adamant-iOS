//
//  DelegateModel.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

extension Delegates {

    public struct DelegateModel: APIModel {

        public let username: String

        public let vote: String

        public let rewards: String?

        public let producedblocks: Int?

        public let missedblocks: Int?

        public let rate: Int?

        public let approval: Double?

        public let productivity: Double?

        public let rank: Int?

        // MARK: - Hashable

        public static func == (lhs: DelegateModel, rhs: DelegateModel) -> Bool {
            return lhs.username == rhs.username
        }

        public var hashValue: Int {
            return username.hashValue
        }
    }
}
