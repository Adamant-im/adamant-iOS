//
//  Crypto.swift
//  Adamant
//
//  Created by Anton Boyarkin on 01/08/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium
import CryptoSwift

public typealias Bytes = Array<UInt8>

public struct Crypto {
    public static let sign = Sign()
    public static let box = Box()
    public static let secretBox = SecretBox()
    public static let ed2Curve = ED2Curve()
}

public struct Sign {
    public var SignBytes: Int { return Int(crypto_sign_bytes()) }
    public var PublicKeyBytes: Int { return Int(crypto_sign_publickeybytes()) }
    public var SecretKeyBytes: Int { return Int(crypto_sign_secretkeybytes()) }
    
    public func keypair(from seed: Bytes) -> (publicKey: Bytes, privateKey: Bytes)? {
        var publicKey = Bytes(count: PublicKeyBytes)
        var privateKey = Bytes(count: SecretKeyBytes)
        
        guard .SUCCESS == crypto_sign_seed_keypair(
            &publicKey,
            &privateKey,
            seed
            ).exitCode else { return nil }
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
    
    public func signature(message: Bytes, secretKey: Bytes) -> Bytes? {
        guard secretKey.count == SecretKeyBytes else { return nil }
        var signature = Array<UInt8>(count: SignBytes)
        
        guard .SUCCESS == crypto_sign_detached (
            &signature,
            nil,
            message, UInt64(message.count),
            secretKey
            ).exitCode else { return nil }
        
        return signature
    }
}

public struct ED2Curve {
    private var KeyBytes: Int { return Int(crypto_scalarmult_curve25519_bytes()) }
    
    public func publicKey(_ key: Bytes) -> Bytes? {
        var publicKey = Bytes(count: KeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_pk_to_curve25519(
            &publicKey,
            key
            ).exitCode else { return nil }
        
        return publicKey
    }
    
    public func privateKey(_ key: Bytes) -> Bytes? {
        var privateKey = Bytes(count: KeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_sk_to_curve25519(
            &privateKey,
            key
            ).exitCode else { return nil }
        
        return privateKey
    }
}

public struct Box: NonceGenerator {
    public var MacBytes: Int { return Int(crypto_box_macbytes()) }
    public var NonceBytes: Int { return Int(crypto_box_noncebytes()) }
    public var PublicKeyBytes: Int { return Int(crypto_box_publickeybytes()) }
    public var SecretKeyBytes: Int { return Int(crypto_box_secretkeybytes()) }
    
    public func seal(message: Bytes, recipientPublicKey: Bytes, senderSecretKey: Bytes) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
        guard recipientPublicKey.count == PublicKeyBytes,
            senderSecretKey.count == SecretKeyBytes
            else { return nil }
        
        var authenticatedCipherText = Bytes(count: message.count + MacBytes)
        let nonce = self.nonce()
        
        guard .SUCCESS == crypto_box_easy(
            &authenticatedCipherText,
            message,
            CUnsignedLongLong(message.count),
            nonce,
            recipientPublicKey,
            senderSecretKey
            ).exitCode else { return nil }
        
        return (authenticatedCipherText: authenticatedCipherText, nonce: nonce)
    }
    
    public func open(authenticatedCipherText: Bytes, senderPublicKey: Bytes, recipientSecretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard nonce.count == NonceBytes,
            authenticatedCipherText.count >= MacBytes,
            senderPublicKey.count == PublicKeyBytes,
            recipientSecretKey.count == SecretKeyBytes
            else { return nil }
        
        var message = Bytes(count: authenticatedCipherText.count - MacBytes)
        
        guard .SUCCESS == crypto_box_open_easy(
            &message,
            authenticatedCipherText, UInt64(authenticatedCipherText.count),
            nonce,
            senderPublicKey,
            recipientSecretKey
            ).exitCode else { return nil }
        
        return message
    }
}

public struct SecretBox: NonceGenerator {
    public var MacBytes: Int { return Int(crypto_secretbox_macbytes()) }
    public var NonceBytes: Int { return Int(crypto_secretbox_noncebytes()) }
    public var KeyBytes: Int { return Int(crypto_secretbox_keybytes()) }

    public func seal(message: Bytes, secretKey: Bytes) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
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
    
    public func open(authenticatedCipherText: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
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
}

public protocol NonceGenerator {
    var NonceBytes: Int { get }
}

extension NonceGenerator {
    /// Generates a random nonce.
    public func nonce() -> Bytes {
        var nonce = Bytes(count: NonceBytes)
        randombytes_buf(&nonce, NonceBytes)
        return nonce
    }
}

// MARK:- Helpers
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
