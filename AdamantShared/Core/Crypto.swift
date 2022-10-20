//
//  Crypto.swift
//  Adamant
//
//  Created by Anton Boyarkin on 01/08/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Clibsodium
import CryptoSwift

public typealias Bytes = [UInt8]

struct Crypto {
    static let sign = Sign()
    static let box = Box()
    static let secretBox = SecretBox()
    static let ed2Curve = ED2Curve()
}

struct Sign {
    var SignBytes: Int { return Int(crypto_sign_bytes()) }
    var PublicKeyBytes: Int { return Int(crypto_sign_publickeybytes()) }
    var SecretKeyBytes: Int { return Int(crypto_sign_secretkeybytes()) }
    
    func keypair(from seed: Bytes) -> (publicKey: Bytes, privateKey: Bytes)? {
        var publicKey = Bytes(count: PublicKeyBytes)
        var privateKey = Bytes(count: SecretKeyBytes)
        
        guard .SUCCESS == crypto_sign_seed_keypair(
            &publicKey,
            &privateKey,
            seed
            ).exitCode else { return nil }
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
    
    func signature(message: Bytes, secretKey: Bytes) -> Bytes? {
        guard secretKey.count == SecretKeyBytes else { return nil }
        var signature = [UInt8](count: SignBytes)
        
        guard .SUCCESS == crypto_sign_detached(
            &signature,
            nil,
            message, UInt64(message.count),
            secretKey
            ).exitCode else { return nil }
        
        return signature
    }
}

struct ED2Curve {
    var KeyBytes: Int { return Int(crypto_scalarmult_curve25519_bytes()) }
    
    func publicKey(_ key: Bytes) -> Bytes? {
        var publicKey = Bytes(count: KeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_pk_to_curve25519(
            &publicKey,
            key
            ).exitCode else { return nil }
        
        return publicKey
    }
    
    func privateKey(_ key: Bytes) -> Bytes? {
        var privateKey = Bytes(count: KeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_sk_to_curve25519(
            &privateKey,
            key
            ).exitCode else { return nil }
        
        return privateKey
    }
}

struct Box: NonceGenerator {
    var MacBytes: Int { return Int(crypto_box_macbytes()) }
    var NonceBytes: Int { return Int(crypto_box_noncebytes()) }
    var PublicKeyBytes: Int { return Int(crypto_box_publickeybytes()) }
    var SecretKeyBytes: Int { return Int(crypto_box_secretkeybytes()) }
    
    func seal(message: Bytes, recipientPublicKey: Bytes, senderSecretKey: Bytes) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
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
    
    func open(authenticatedCipherText: Bytes, senderPublicKey: Bytes, recipientSecretKey: Bytes, nonce: Bytes) -> Bytes? {
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

struct SecretBox: NonceGenerator {
    var MacBytes: Int { return Int(crypto_secretbox_macbytes()) }
    var NonceBytes: Int { return Int(crypto_secretbox_noncebytes()) }
    var KeyBytes: Int { return Int(crypto_secretbox_keybytes()) }

    func seal(message: Bytes, secretKey: Bytes) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
        guard secretKey.count == KeyBytes else { return nil }
        var authenticatedCipherText = Bytes(count: message.count + MacBytes)
        let nonce = self.nonce()
        
        guard .SUCCESS == crypto_secretbox_easy(
            &authenticatedCipherText,
            message, UInt64(message.count),
            nonce,
            secretKey
            ).exitCode else { return nil }
        
        return (authenticatedCipherText: authenticatedCipherText, nonce: nonce)
    }
    
    func open(authenticatedCipherText: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard authenticatedCipherText.count >= MacBytes else { return nil }
        var message = Bytes(count: authenticatedCipherText.count - MacBytes)
        
        guard .SUCCESS == crypto_secretbox_open_easy(
            &message,
            authenticatedCipherText, UInt64(authenticatedCipherText.count),
            nonce,
            secretKey
            ).exitCode else { return nil }
        
        return message
    }
}

protocol NonceGenerator {
    var NonceBytes: Int { get }
}

extension NonceGenerator {
    /// Generates a random nonce.
    func nonce() -> Bytes {
        var nonce = Bytes(count: NonceBytes)
        randombytes_buf(&nonce, NonceBytes)
        return nonce
    }
}

extension Array where Element == UInt8 {
    init (count bytes: Int) {
        self.init(repeating: 0, count: bytes)
    }
    
    public var utf8String: String? {
        return String(data: Data(self), encoding: .utf8)
    }
    
    func toData() -> Data {
        return Data(self)
    }
}

extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

private enum ExitCode {
    case SUCCESS
    case FAILURE
    
    init (from int: Int32) {
        switch int {
        case 0:  self = .SUCCESS
        default: self = .FAILURE
        }
    }
}

fileprivate extension Int32 {
    var exitCode: ExitCode { return ExitCode(from: self) }
}

extension Sequence where Self.Element == UInt8 {
    internal func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
