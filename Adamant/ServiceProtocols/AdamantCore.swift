//
//  AdamantCore.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol AdamantCore {
	func createHashFor(passphrase: String) -> String?
	
	func createKeypairFor(passphrase: String) -> Keypair?
	
	func sign(transaction: NormalizedTransaction, senderId: String, keypair: Keypair) -> String?
}
