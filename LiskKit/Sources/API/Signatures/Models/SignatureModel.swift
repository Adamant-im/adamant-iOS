//
//  SignatureModel.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

extension Signatures {

    public struct SignatureModel: APIModel {

        public let transactionId: String

        public let publicKey: String

        public let signature: String
    }
}
