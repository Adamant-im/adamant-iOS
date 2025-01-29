//
//  AdamantCoreMock.swift
//  Adamant
//
//  Created by Christian Benua on 29.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class AdamantCoreMock: AdamantCore {
    
    // MARK: - Keys

    func createHashFor(passphrase: String) -> String? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func createKeypairFor(passphrase: String) -> Keypair? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    // MARK: - Signing transactions
    
    var invokedSign: Bool = false
    var invokedSignCount: Int = 0
    var invokedSignParameters: (transaction: SignableTransaction, senderId: String, keypair: Keypair)?
    var stubbedSignResult: String?
    
    func sign(transaction: SignableTransaction, senderId: String, keypair: Keypair) -> String? {
        invokedSign = true
        invokedSignCount += 1
        invokedSignParameters = (transaction, senderId, keypair)
        return stubbedSignResult
    }
    
    // MARK: - Encoding messages
    
    var invokedEncodeMessage: Bool = false
    var invokedEncodeMessageCount: Int = 0
    var invokedEncodeMessageParameters: (message: String, recipientPublicKey: String, privateKey: String)?
    var stubbedEncodeMessageResult: (message: String, nonce: String)?
    
    func encodeMessage(_ message: String, recipientPublicKey: String, privateKey: String) -> (message: String, nonce: String)? {
        invokedEncodeMessage = true
        invokedEncodeMessageCount += 1
        invokedEncodeMessageParameters = (message, recipientPublicKey, privateKey)
        return stubbedEncodeMessageResult
    }
    
    func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey: String, privateKey: String) -> String? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func encodeValue(_ value: [String : Any], privateKey: String) -> (message: String, nonce: String)? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func decodeValue(rawMessage: String, rawNonce: String, privateKey: String) -> String? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func encodeData(_ data: Data, recipientPublicKey publicKey: String, privateKey privateKeyHex: String) -> (data: Data, nonce: String)? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func decodeData(_ data: Data, rawNonce: String, senderPublicKey senderKeyHex: String, privateKey privateKeyHex: String) -> Data? {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
