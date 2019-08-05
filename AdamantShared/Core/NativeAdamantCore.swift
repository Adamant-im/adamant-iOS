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

class NativeAdamantCore {
    // MARK: - Messages
    
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
    
    
    // MARK: - Values
    
    func encodeValue(_ value: [String: Any], privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
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
    
    // MARK: - Passphrases
    
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
    
    func createHashFor(passphrase: String) -> String? {
        guard let hash = createRawHashFor(passphrase: passphrase) else {
            print("Unable create hash from passphrase")
            return nil
        }
        
        return hash.hexString()
    }
    
    private func createRawHashFor(passphrase: String) -> [UInt8]? {
        guard let seed = Mnemonic.seed(passphrase: passphrase) else {
            print("FAIL to create Seed from passphrase bytes")
            return nil
        }
        
        return seed.sha256()
    }
}

// MARK: - String

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
    
    static func random(length: Int = 32, alphabet: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        let upperBound = UInt32(alphabet.count)
        return String((0..<length).map { _ -> Character in
            let index = alphabet.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(upperBound)))
            return alphabet[index]
        })
    }
}
