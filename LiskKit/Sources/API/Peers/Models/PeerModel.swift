//
//  PeerModel.swift
//  Lisk
//
//  Created by Andrew Barba on 1/8/18.
//

import Foundation

extension Peers {

    public struct PeerModel: APIModel {

        public enum State: UInt8, Decodable {
            case banned = 0
            case disconnected = 1
            case connected = 2
        }

        public let ip: String

        public let httpPort: Int?

        public let wsPort: Int?

        public let os: String?

        public let version: String?

        public let state: State

        public let height: Int?

        public let broadhash: String?

        public let nonce: String?

        // MARK: - Hashable

        public static func == (lhs: PeerModel, rhs: PeerModel) -> Bool {
            return lhs.ip == rhs.ip
        }

        public var hashValue: Int {
            return ip.hashValue
        }
    }
}
