//
//  Mnemonic.swift
//  Adamant
//
//  Created by Anton Boyarkin on 01/08/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CryptoSwift
import CommonKit

enum MnemonicError : Error {
    case randomBytesError
}

extension Mnemonic {
    
    // MARK: - Generating passphrases
    
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
}
