//
//  AdamantCore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol AdamantCore: AnyObject {
    // MARK: - Keys
    func createHashFor(passphrase: String) -> String?
    func createKeypairFor(passphrase: String) -> Keypair?
    func generateNewPassphrase() -> String
    
    // MARK: - Signing transactions
    func sign(transaction: SignableTransaction, senderId: String, keypair: Keypair) -> String?
    
    // MARK: - Encoding messages
    func encodeMessage(_ message: String, recipientPublicKey: String, privateKey: String) -> (message: String, nonce: String)?
    func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey: String, privateKey: String) -> String?
    func encodeValue(_ value: [String: Any], privateKey: String) -> (message: String, nonce: String)?
    func decodeValue(rawMessage: String, rawNonce: String, privateKey: String) -> String?
}

protocol SignableTransaction {
    var type: TransactionType { get }
    var amount: Decimal { get }
    var senderPublicKey: String { get }
    var requesterPublicKey: String? { get }
    var timestamp: UInt64 { get }
    var recipientId: String? { get }
    
    var asset: TransactionAsset { get }
}
