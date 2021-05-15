//
//  NodeConstantsModel.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

extension Node {

    public struct NodeConstantsModel: APIModel {

        public let epoch: String

        public let milestone: String

        public let build: String

        public let commit: String

        public let version: String

        public let nethash: String

        public let supply: String

        public let reward: String

        public let nonce: String

        public let fees: NodeConstantsFeesModel
    }

    public struct NodeConstantsFeesModel: APIModel {

        public let send: String

        public let vote: String

        public let secondSignature: String

        public let delegate: String

        public let multisignature: String

        public let dappRegistration: String

        public let dappWithdrawal: String

        public let dappDeposit: String

        public let data: String
    }
}
