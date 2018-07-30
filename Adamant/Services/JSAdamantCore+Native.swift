//
//  JSAdamantCore+Native.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium
import BigInt
import CryptoSwift

extension JSAdamantCore {
    
    func createKeypairFor(rawHash: [UInt8]) -> Keypair? {
        guard let keypair = makeKeypairFrom(seed: rawHash) else {
            print("Unable create Keypair from seed")
            return nil
        }
        
        return Keypair(publicKey: keypair.publicKey.hexString(), privateKey: keypair.privateKey.hexString())
    }
    
    func createHashFor(passphrase: String) -> String? {
        guard let hash = createPassPhraseHash(passphrase: passphrase) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        return hash.hexString()
    }
    
    func createKeypairFor(passphrase: String) -> Keypair? {
        guard let hash = createPassPhraseHash(passphrase: passphrase) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        guard let keypair = makeKeypairFrom(seed: hash) else {
            print("Unable create Keypair from seed")
            return nil
        }
        
        return Keypair(publicKey: keypair.publicKey.hexString(), privateKey: keypair.privateKey.hexString())
    }
    
    func createPassPhraseHash(passphrase: String) -> [UInt8]? {
        guard let seed = createSeed(passphrase) else {
            print("FAIL to create Seed from passphrase bytes")
            return nil
        }
        
        guard let hash = hashSHA256(seed) else {
            print("FAIL to create SHA256 from seed")
            return nil
        }
        
        return hash
    }
    func encodeValue(_ value: [String: Any], privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
        let data = ["payload": value]
        
        let padded: String = String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz") + JSONStringify(value: data as AnyObject) + String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz")

        let message = padded.bytes
        let privateKey = privateKeyHex.hexBytes()
        
        guard let hash = hashSHA256(privateKey) else {
            print("FAIL to create SHA256 of private key")
            return nil
        }
        
        guard let secretKey = ed2curve(privateKey: hash) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let encrypted = seal(message: message, secretKey: secretKey) else {
            print("FAIL to encrypt")
            return nil
        }
        
        let encryptedMessage = encrypted.authenticatedCipherText.hexString()
        let nonce = encrypted.nonce.hexString()
        
        return (message: encryptedMessage, nonce: nonce)
    }
    
    func decodeValue(rawMessage: String, rawNonce: String, privateKey privateKeyHex: String) -> String? {
        let message = rawMessage.hexBytes()
        let nonce = rawNonce.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let hash = hashSHA256(privateKey) else {
            print("FAIL to create SHA256 of private key")
            return nil
        }
        
        guard let secretKey = ed2curve(privateKey: hash) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let decrepted = open(authenticatedCipherText: message, secretKey: secretKey, nonce: nonce) else {
            print("FAIL to decrypt")
            return nil
        }
        
        return decrepted.utf8String
    }
    
    private func seal(message: Bytes, secretKey: Bytes) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
        guard secretKey.count == KeyBytes else { return nil }
        var authenticatedCipherText = Bytes(count: message.count + MacBytes)
        let nonce = self.nonce()
        
        guard .SUCCESS == crypto_secretbox_easy (
            &authenticatedCipherText,
            message, UInt64(message.count),
            nonce,
            secretKey
            ).exitCode else { return nil }
        
        return (authenticatedCipherText: authenticatedCipherText, nonce: nonce)
    }
    
    private func open(authenticatedCipherText: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard authenticatedCipherText.count >= MacBytes else { return nil }
        var message = Bytes(count: authenticatedCipherText.count - MacBytes)
        
        guard .SUCCESS == crypto_secretbox_open_easy (
            &message,
            authenticatedCipherText, UInt64(authenticatedCipherText.count),
            nonce,
            secretKey
            ).exitCode else { return nil }
        
        return message
    }
    
    private func hashSHA256(_ input: Bytes) -> Bytes? {
        var hash = Bytes(count: HashSHA256Bytes)
        
        guard .SUCCESS == crypto_hash_sha256(
            &hash,
            input, UInt64(input.count)
            ).exitCode else { return nil }
        
        return hash
    }
    
    private func ed2curve(privateKey: Bytes) -> Bytes? {
        var secretKey = Bytes(count: SecretCurveKeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_sk_to_curve25519(
            &secretKey,
            privateKey
            ).exitCode else { return nil }
        
        return secretKey
    }
    
    private func nonce() -> Bytes {
        var nonce = Bytes(count: NonceBytes)
        randombytes_buf(&nonce, NonceBytes)
        return nonce
    }
    
    private func createSeed(_ passphrase: String) -> [UInt8]? {
        let password = passphrase.decomposedStringWithCompatibilityMapping
        let salt = ("mnemonic").decomposedStringWithCompatibilityMapping
        
        if let seed = try? PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: 2048, keyLength: 64, variant: HMAC.Variant.sha512).calculate() {
            return seed
        } else {
            return nil
        }
    }
    
    private func makeKeypairFrom(seed: Bytes) -> (publicKey: Bytes, privateKey: Bytes)? {
        var publicKey = Bytes(count: PublicKeyBytes)
        var privateKey = Bytes(count: SecretKeyBytes)
        
        guard .SUCCESS == crypto_sign_seed_keypair(
            &publicKey,
            &privateKey,
            seed
            ).exitCode else { return nil }
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
}

// MARK:- Helpers
public let HashSHA256Bytes = Int(crypto_hash_sha256_bytes())
public let SecretCurveKeyBytes = Int(crypto_scalarmult_curve25519_bytes())
public let MacBytes = Int(crypto_secretbox_macbytes())
public let NonceBytes = Int(crypto_secretbox_noncebytes())
public let KeyBytes = Int(crypto_secretbox_keybytes())
public let SeedBytes = Int(crypto_sign_seedbytes())
public let PublicKeyBytes = Int(crypto_sign_publickeybytes())
public let SecretKeyBytes = Int(crypto_sign_secretkeybytes())

public typealias Bytes = Array<UInt8>

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension Array where Element == UInt8 {
    init (count bytes: Int) {
        self.init(repeating: 0, count: bytes)
    }
    
    public var utf8String: String? {
        return String(data: Data(bytes: self), encoding: .utf8)
    }
    
    func toData() -> Data {
        return Data(bytes: self)
    }
}

extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

extension String {
    var bytes: Bytes { return Bytes(self.utf8) }
    
    func hexBytes() -> [UInt8] {
        return (0..<count/2).reduce([]) { res, i in
            let indexStart = index(startIndex, offsetBy: i * 2)
            let indexEnd = index(indexStart, offsetBy: 2)
            let substring = self[indexStart..<indexEnd]
            return res + [UInt8(substring, radix: 16) ?? 0]
        }
    }
    
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    subscript (i: Int) -> Character
    {
        return self[index(startIndex, offsetBy:i)]
    }
    
    static func random(length: Int = 32, alphabet: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String
    {
        let upperBound = UInt32(alphabet.count)
        return String((0..<length).map { _ -> Character in
            return alphabet[Int(arc4random_uniform(upperBound))]
        })
    }
}

enum ExitCode {
    case SUCCESS
    case FAILURE
    
    init (from int: Int32) {
        switch int {
        case 0:  self = .SUCCESS
        default: self = .FAILURE
        }
    }
}

extension Int32 {
    var exitCode: ExitCode { return ExitCode(from: self) }
}

extension Sequence where Self.Element == UInt8 {
    internal func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : []
    
    if JSONSerialization.isValidJSONObject(value) {
        if let data = try? JSONSerialization.data(withJSONObject: value, options: options) {
            if let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
    }
    
    return ""
}
