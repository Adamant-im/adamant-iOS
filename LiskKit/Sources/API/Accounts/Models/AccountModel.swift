//
//  AccountModel.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

extension Accounts {

    public struct LegacyAccountModel: APIModel {

        public let address: String

        public let publicKey: String

        public let balance: String?

        public let unconfirmedBalance: String?

        public let secondPublicKey: String?

        public let delegate: Delegates.DelegateModel?

        // MARK: - Hashable

        public static func == (lhs: LegacyAccountModel, rhs: LegacyAccountModel) -> Bool {
            return lhs.address == rhs.address
        }

        public var hashValue: Int {
            return address.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(address)
        }
    }
    
    public struct AccountModel: APIModel {

        private struct Sequence: APIModel {
            var nonce: String?
        }

        private struct Token: APIModel {
            var balance: String?
        }

        public let address: String
        private let sequence: Sequence?
        private let token: Token?

        public var nonce: String {
            return sequence?.nonce ?? "0"
        }

        public var balance: String? {
            return token?.balance
        }

        // MARK: - Hashable

        public static func == (lhs: AccountModel, rhs: AccountModel) -> Bool {
            return lhs.address == rhs.address
        }

        public var hashValue: Int {
            return address.hashValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(address)
        }
    }
}
