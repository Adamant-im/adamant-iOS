//
//  AdamantCore.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 05.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation

protocol AdamantCore {
	func createHashFor(passphrase: String) -> AdamantHash?
	
	func createKeypairFor(hash: AdamantHash) -> Keypair?
	func createKeypairFor(passphrase: String) -> Keypair?
}
