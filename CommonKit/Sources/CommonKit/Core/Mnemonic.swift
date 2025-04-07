//
//  Mnemonic.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import CryptoSwift
import Foundation

public enum Mnemonic {
    // MARK: - Passphrase seeds

    public static func seed(passphrase: String, salt: String = "mnemonic") -> [UInt8]? {
        let password = passphrase.decomposedStringWithCompatibilityMapping
        let salt = salt.decomposedStringWithCompatibilityMapping

        if let seed = try? PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: 2048, keyLength: 64, variant: HMAC.Variant.sha2(.sha512))
            .calculate()
        {
            return seed
        } else {
            return nil
        }
    }

    public static func seed(mnemonic m: [String], passphrase: String = "") -> [UInt8]? {
        let mnemonic = m.joined(separator: " ")
        let salt = ("mnemonic" + passphrase)

        return seed(passphrase: mnemonic, salt: salt)
    }
}
