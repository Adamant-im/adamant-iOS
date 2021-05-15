//
//  DappModel.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

extension Dapps {

    public struct DappModel: APIModel {

        public let transactionId: String

        public let icon: String?

        public let category: Int?

        public let type: Int

        public let link: String?

        public let tags: String?

        public let description: String?

        public let name: String

        // MARK: - Hashable

        public static func == (lhs: DappModel, rhs: DappModel) -> Bool {
            return lhs.name == rhs.name
        }

        public var hashValue: Int {
            return name.hashValue
        }
    }
}
