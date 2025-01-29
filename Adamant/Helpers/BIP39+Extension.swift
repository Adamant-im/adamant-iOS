//
//  BIP39+Extension.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Web3Core
import Foundation

extension BIP39 {
    /// Generates a binary seed consider two cases:
    /// - If `passphrase is empty`, generates a mnemonic phrase using old adamant approach to ensure compatibility with older wallets.
    /// - If `passphrase is not empty`, generates a mnemonic phrase using BIP39 approach.
    static func makeBinarySeed(withMnemonicSentence passphrase: String, withSalt salt: String) -> Data? {
        guard !salt.isEmpty else {
            return passphrase.data(using: .utf8)!.sha256()
        }
        
        return BIP39.seedFromMmemonics(passphrase, password: salt, language: .english)
    }
}
