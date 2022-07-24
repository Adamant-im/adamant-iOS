//
//  AddressGenerator.swift
//  Adamant
//
//  Created by Andrey on 11.07.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

enum AddressGenerator {
    static func generateAddress(publicKey: String) -> String {
        let publicKeyHashBytes = publicKey.hexBytes().sha256()
        let data = Data(publicKeyHashBytes)
        let number = data.withUnsafeBytes { $0.load(as: UInt.self) }
        return "U\(number)"
    }
}

// algorithm:
// https://github.com/Adamant-im/adamant/wiki/Generating-ADAMANT-account-and-key-pair#3-a-users-adm-wallet-address-is-generated-from-the-publickeys-sha-256-hash
