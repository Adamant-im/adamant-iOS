//
//  AuthAccount.swift
//
//
//  Created by Stanislav Jelezoglo on 18.12.2023.
//

import Foundation

public struct AuthAccount: Decodable {
    public let nonce: String
}

/*
 {
   "nonce": "0",
   "numberOfSignatures": 0,
   "mandatoryKeys": [],
   "optionalKeys": []
 }
 */
