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

public enum Crypto {
    public static let sign = Sign()
    public static let box = Box()
    public static let secretBox = SecretBox()
    public static let ed2Curve = ED2Curve()
}

public struct Sign: Sendable {
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
        var signature = [UInt8](count: SignBytes)
        
        guard .SUCCESS == crypto_sign_detached(
            &signature,
            nil,
            message, UInt64(message.count),
            secretKey
            ).exitCode else { return nil }
        
        return signature
    }
    
    public init() {}
}

public struct ED2Curve: Sendable {
    public var KeyBytes: Int { return Int(crypto_scalarmult_curve25519_bytes()) }
    
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
    
    public func seal(
        message: Bytes,
        recipientPublicKey: Bytes,
        senderSecretKey: Bytes
    ) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
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
    
    public init() {}
}

public struct SecretBox: NonceGenerator {
    public var MacBytes: Int { return Int(crypto_secretbox_macbytes()) }
    public var NonceBytes: Int { return Int(crypto_secretbox_noncebytes()) }
    public var KeyBytes: Int { return Int(crypto_secretbox_keybytes()) }

    public func seal(
        message: Bytes,
        secretKey: Bytes
    ) -> (authenticatedCipherText: Bytes, nonce: Bytes)? {
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
    
    public func open(authenticatedCipherText: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
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

public protocol NonceGenerator: Sendable {
    var NonceBytes: Int { get }
}

public extension NonceGenerator {
    /// Generates a random nonce.
    func nonce() -> Bytes {
        var nonce = Bytes(count: NonceBytes)
        randombytes_buf(&nonce, NonceBytes)
        return nonce
    }
}

public extension Array where Element == UInt8 {
    init (count bytes: Int) {
        self.init(repeating: 0, count: bytes)
    }
    
    var utf8String: String? {
        return String(data: Data(self), encoding: .utf8)
    }
    
    func toData() -> Data {
        return Data(self)
    }
}

public extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

public extension Sequence where Self.Element == UInt8 {
    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

private enum ExitCode {
    case SUCCESS
    case FAILURE
    
    init(from int: Int32) {
        switch int {
        case 0:  self = .SUCCESS
        default: self = .FAILURE
        }
    }
}

private extension Int32 {
    var exitCode: ExitCode { return ExitCode(from: self) }
}
