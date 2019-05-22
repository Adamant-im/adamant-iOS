//
//  Mnemonic.swift
//  Adamant
//
//  Created by Anton Boyarkin on 01/08/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CryptoSwift

enum MnemonicError : Error {
    case randomBytesError
}

class Mnemonic {
    static func generate() throws -> [String] {
        let byteCount = 16
        var bytes = Data(count: byteCount)
        let status = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0) }
        guard status == errSecSuccess else { throw MnemonicError.randomBytesError }
        return generate(entropy: bytes)
    }
    
    static func generate(entropy : Data) -> [String] {
        var bin = String(entropy.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        
        let hash = entropy.sha256()
        let bits = entropy.count * 8
        let cs = bits / 32
        
        let hashbits = String(hash.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        let checksum = String(hashbits.prefix(cs))
        bin += checksum
        
        var mnemonic = [String]()
        for i in 0..<(bin.count / 11) {
            let wi = Int(bin[bin.index(bin.startIndex, offsetBy: i * 11)..<bin.index(bin.startIndex, offsetBy: (i + 1) * 11)], radix: 2)!
            mnemonic.append(String(WordList.english[wi]))
        }
        
        return mnemonic
    }
    
    static func seed(mnemonic m: [String], passphrase: String = "") -> [UInt8]? {
        let mnemonic = m.joined(separator: " ")
        let salt = ("mnemonic" + passphrase)
        
        return seed(passphrase: mnemonic, salt: salt)
    }
    
    static func seed(passphrase: String, salt: String = "mnemonic") -> [UInt8]? {
        let password = passphrase.decomposedStringWithCompatibilityMapping
        let salt = salt.decomposedStringWithCompatibilityMapping
        
        if let seed = try? PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: 2048, keyLength: 64, variant: HMAC.Variant.sha512).calculate() {
            return seed
        } else {
            return nil
        }
    }
    
    private init() {}
}
