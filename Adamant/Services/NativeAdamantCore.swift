//
//  NativeAdamantCore.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CryptoSwift

class NativeAdamantCore : AdamantCore {
    
    func createHashFor(passphrase: String) -> String? {
        guard let hash = createRawHashFor(passphrase: passphrase) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        return hash.hexString()
    }
    
    func createKeypairFor(passphrase: String) -> Keypair? {
        guard let hash = createRawHashFor(passphrase: passphrase) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        guard let keypair = Crypto.sign.keypair(from: hash) else {
            print("Unable create Keypair from seed")
            return nil
        }
        
        return Keypair(publicKey: keypair.publicKey.hexString(), privateKey: keypair.privateKey.hexString())
    }
    
    func generateNewPassphrase() -> String {
        if let passphrase = try? Mnemonic.generate().joined(separator: " ") {
            return passphrase
        }
        return ""
    }
    
    func sign(transaction: SignableTransaction, senderId: String, keypair: Keypair) -> String? {
        let privateKey = keypair.privateKey.hexBytes()
        let hash = transaction.bytes.sha256()
        
        guard let signature = Crypto.sign.signature(message: hash, secretKey: privateKey) else {
            print("FAIL to sign of transaction")
            return nil
        }
        
        return signature.hexString()
    }
    
    func encodeMessage(_ message: String, recipientPublicKey publicKey: String, privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
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
    
    func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey senderKeyHex: String, privateKey privateKeyHex: String) -> String? {
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
    
    func encodeValue(_ value: [String: Any], privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
        let data = ["payload": value]
        
        let padded: String = String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz") + JSONStringify(value: data as AnyObject) + String.random(length: Int(arc4random_uniform(10)), alphabet: "abcdefghijklmnopqrstuvwxyz")

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
    
    func decodeValue(rawMessage: String, rawNonce: String, privateKey privateKeyHex: String) -> String? {
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

    // MARK: - Private tools
    private func createRawHashFor(passphrase: String) -> [UInt8]? {
        guard let seed = Mnemonic.seed(passphrase: passphrase) else {
            print("FAIL to create Seed from passphrase bytes")
            return nil
        }
        
        return seed.sha256()
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

// MARK: - Bytes
extension SignableTransaction {
    
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
