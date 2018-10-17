//
//  KeychainStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import KeychainAccess
import RNCryptor

class KeychainStore: SecuredStore {
	let keychain = Keychain(service: "im.adamant")
	
	// For AppStore builds, we use a real password.
	// See keychain-toAppstore.sh & keychain-toDebug.sh scripts. They runs automaticatlly for Release builds.
	private let 🍩 = "standard-berkeley-silt-excavate-sprain-platter-flatboat-jockey-sisal-catapult"
	
	func get(_ key: String) -> String? {
		if let rawData = keychain[key],
			let encryptedData = Data(base64Encoded: rawData),
			let data = try? RNCryptor.decrypt(data: encryptedData, withPassword: 🍩),
			let string = String(data: data, encoding: .utf8) {
			return string
		}
		
		return nil
	}
	
	func set(_ value: String, for key: String) {
		if let data = value.data(using: .utf8) {
			let encryptedString = RNCryptor.encrypt(data: data, withPassword: 🍩).base64EncodedString()
			try? keychain.set(encryptedString, key: key)
		}
	}
	
	func remove(_ key: String) {
		try? keychain.remove(key)
	}
}
