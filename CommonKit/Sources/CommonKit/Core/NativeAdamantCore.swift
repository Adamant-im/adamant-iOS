//
//  NativeAdamantCore.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CryptoSwift

/*
 * Native Adamanat Core
 * Decoding and Encoding for messages and values
 */

public final class NativeAdamantCore: AdamantCore {
    // MARK: - Messages
    
    public func encodeMessage(_ message: String, recipientPublicKey publicKey: String, privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
        let message = message.bytes
        let recipientKey = publicKey.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let publicKey = Crypto.ed2Curve.publicKey(recipientKey) else {
            print("FAIL to create ed2curve publick key from SHA256")
            return nil
        }
        
        guard let secretKey = Crypto.ed2Curve.privateKey(privateKey) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let encrypted = Crypto.box.seal(message: message, recipientPublicKey: publicKey, senderSecretKey: secretKey) else {
            print("FAIL to encrypt")
            return nil
        }
        
        let encryptedMessage = encrypted.authenticatedCipherText.hexString()
        let nonce = encrypted.nonce.hexString()
        
        return (message: encryptedMessage, nonce: nonce)
    }
    
    public func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey senderKeyHex: String, privateKey privateKeyHex: String) -> String? {
        let message = rawMessage.hexBytes()
        let nonce = rawNonce.hexBytes()
        let senderKey = senderKeyHex.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let publicKey = Crypto.ed2Curve.publicKey(senderKey) else {
            print("FAIL to create ed2curve publick key from SHA256")
            return nil
        }
        
        guard let secretKey = Crypto.ed2Curve.privateKey(privateKey) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let decrepted = Crypto.box.open(authenticatedCipherText: message, senderPublicKey: publicKey, recipientSecretKey: secretKey, nonce: nonce) else {
            print("FAIL to decrypt")
            return nil
        }
        
        return decrepted.utf8String
    }
    
    public func sign(transaction: SignableTransaction, senderId: String, keypair: Keypair) -> String? {
        let privateKey = keypair.privateKey.hexBytes()
        let hash = transaction.bytes.sha256()
        
        guard let signature = Crypto.sign.signature(message: hash, secretKey: privateKey) else {
            print("FAIL to sign of transaction")
            return nil
        }
        
        return signature.hexString()
    }
    
    public func encodeData(
        _ data: Data,
        recipientPublicKey publicKey: String,
        privateKey privateKeyHex: String
    ) -> (data: Data, nonce: String)? {
        let message = data.bytes
        let recipientKey = publicKey.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let publicKey = Crypto.ed2Curve.publicKey(recipientKey) else {
            print("FAIL to create ed2curve publick key from SHA256")
            return nil
        }
        
        guard let secretKey = Crypto.ed2Curve.privateKey(privateKey) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let encrypted = Crypto.box.seal(message: message, recipientPublicKey: publicKey, senderSecretKey: secretKey) else {
            print("FAIL to encrypt")
            return nil
        }
        
        let encryptedData = encrypted.authenticatedCipherText.toData()
        let nonce = encrypted.nonce.hexString()
        
        return (data: encryptedData, nonce: nonce)
    }
    
    public func decodeData(
        _ data: Data,
        rawNonce: String,
        senderPublicKey senderKeyHex: String,
        privateKey privateKeyHex: String
    ) -> Data? {
        let message = data.bytes
        let nonce = rawNonce.hexBytes()
        let senderKey = senderKeyHex.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let publicKey = Crypto.ed2Curve.publicKey(senderKey) else {
            print("FAIL to create ed2curve publick key from SHA256")
            return nil
        }
        
        guard let secretKey = Crypto.ed2Curve.privateKey(privateKey) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let decrepted = Crypto.box.open(authenticatedCipherText: message, senderPublicKey: publicKey, recipientSecretKey: secretKey, nonce: nonce) else {
            print("FAIL to decrypt")
            return nil
        }
        
        return decrepted.toData()
    }
    // MARK: - Values
    
    public func encodeValue(_ value: [String: Any], privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
        let data = ["payload": value]
        
        let padded: String = String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz") + AdamantUtilities.JSONStringify(value: data as AnyObject) + String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz")
        
        let message = padded.bytes
        let privateKey = privateKeyHex.hexBytes()
        let hash = privateKey.sha256()
        
        guard let secretKey = Crypto.ed2Curve.privateKey(hash) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let encrypted = Crypto.secretBox.seal(message: message, secretKey: secretKey) else {
            print("FAIL to encrypt")
            return nil
        }
        
        let encryptedMessage = encrypted.authenticatedCipherText.hexString()
        let nonce = encrypted.nonce.hexString()
        
        return (message: encryptedMessage, nonce: nonce)
    }
    
    public func decodeValue(rawMessage: String, rawNonce: String, privateKey privateKeyHex: String) -> String? {
        let message = rawMessage.hexBytes()
        let nonce = rawNonce.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        let hash = privateKey.sha256()
        
        guard let secretKey = Crypto.ed2Curve.privateKey(hash) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let decrepted = Crypto.secretBox.open(authenticatedCipherText: message, secretKey: secretKey, nonce: nonce) else {
            print("FAIL to decrypt")
            return nil
        }
        
        return decrepted.utf8String
    }
    
    // MARK: - Passphrases
    
    public func createKeypairFor(passphrase: String, password: String) -> Keypair? {
        guard let hash = createSeedFor(passphrase: passphrase, password: password) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        guard let keypair = Crypto.sign.keypair(from: hash) else {
            print("Unable create Keypair from seed")
            return nil
        }
        
        return Keypair(publicKey: keypair.publicKey.hexString(), privateKey: keypair.privateKey.hexString())
    }
    
    public func createSeedFor(passphrase: String, password: String) -> [UInt8]? {
        guard let seed = Mnemonic.seed(passphrase: passphrase, salt: "mnemonic\(password)") else {
            print("FAIL to create Seed from passphrase bytes")
            return nil
        }
        
        return seed.sha256()
    }
    
    public init() {}
}

// MARK: - String

public extension String {
    func hexBytes() -> [UInt8] {
        return (0..<count/2).reduce([]) { res, i in
            let indexStart = index(startIndex, offsetBy: i * 2)
            let indexEnd = index(indexStart, offsetBy: 2)
            let substring = self[indexStart..<indexEnd]
            return res + [UInt8(substring, radix: 16) ?? 0]
        }
    }
    
    static func random(length: Int = 32, alphabet: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        let upperBound = UInt32(alphabet.count)
        return String((0..<length).map { _ -> Character in
            let index = alphabet.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(upperBound)))
            return alphabet[index]
        })
    }
}

// MARK: - Bytes
private extension SignableTransaction {
    
    var bytes: [UInt8] {
        return
            typeBytes +
                timestampBytes +
                senderPublicKeyBytes +
                requesterPublicKeyBytes +
                recipientIdBytes +
                amountBytes +
                assetBytes +
                signatureBytes +
        signSignatureBytes
    }
    
    var typeBytes: [UInt8] {
        return [UInt8(type.rawValue)]
    }
    
    var timestampBytes: [UInt8] {
        return ByteBackpacker.pack(UInt32(timestamp), byteOrder: .littleEndian)
    }
    
    var senderPublicKeyBytes: [UInt8] {
        return senderPublicKey.hexBytes()
    }
    
    var requesterPublicKeyBytes: [UInt8] {
        return requesterPublicKey?.hexBytes() ?? []
    }
    
    var recipientIdBytes: [UInt8] {
        guard
            let value = recipientId?.replacingOccurrences(of: "U", with: ""),
            let number = UInt64(value) else { return Bytes(count: 8) }
        return ByteBackpacker.pack(number, byteOrder: .bigEndian)
    }
    
    var amountBytes: [UInt8] {
        let value = (self.amount.shiftedToAdamant() as NSDecimalNumber).uint64Value
        let bytes = ByteBackpacker.pack(value, byteOrder: .littleEndian)
        return bytes
    }
    
    var signatureBytes: [UInt8] {
        return []
    }
    
    var signSignatureBytes: [UInt8] {
        return []
    }
    
    var assetBytes: [UInt8] {
        switch type {
        case .chatMessage:
            guard let msg = asset.chat?.message, let own = asset.chat?.ownMessage, let type = asset.chat?.type else { return [] }
            
            return msg.hexBytes() + own.hexBytes() + ByteBackpacker.pack(UInt32(type.rawValue), byteOrder: .littleEndian)
            
        case .state:
            guard let key = asset.state?.key, let value = asset.state?.value, let type = asset.state?.type else { return [] }
            
            return value.bytes + key.bytes + ByteBackpacker.pack(UInt32(type.rawValue), byteOrder: .littleEndian)
            
        case .vote:
            guard
                let votes = asset.votes?.votes
                else { return [] }
            
            var bytes = [UInt8]()
            for vote in votes {
                bytes += vote.bytes
            }
            
            return bytes
            
        default:
            return []
        }
    }
}
