//
//  KeychainStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainStore: SecuredStore {
	let keychain = Keychain(service: "im.adamant")
	
	func get(_ key: String) -> String? {
		return keychain[key]
	}
	
	func set(_ value: String, for key: String) {
		keychain[key] = value
	}
	
	func remove(_ key: String) {
		try? keychain.remove(key)
	}
}
