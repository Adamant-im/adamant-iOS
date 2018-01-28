//
//  AdamantCore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol AdamantCore {
	// MARK: - Keys
	func createHashFor(passphrase: String) -> String?
	func createKeypairFor(passphrase: String) -> Keypair?
	func generateNewPassphrase() -> String
	
	// MARK: - Signing transactions
	func sign(transaction: NormalizedTransaction, senderId: String, keypair: Keypair) -> String?
	
	// MARK: - Encoding messages
	func encodeMessage(_ message: String, recipientPublicKey: String, privateKey: String) -> (message: String, nonce: String)?
	func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey: String, privateKey: String) -> String?
}
