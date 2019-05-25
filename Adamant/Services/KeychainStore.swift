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
	
	func get(_ key: String) -> String? {
		if let rawData = keychain[key],
			let encryptedData = Data(base64Encoded: rawData),
			let data = try? RNCryptor.decrypt(data: encryptedData, withPassword: AdamantSecret.keychainAppStorePassword),
			let string = String(data: data, encoding: .utf8) {
			return string
		}
		
		return nil
	}
	
	func set(_ value: String, for key: String) {
		if let data = value.data(using: .utf8) {
			try? keychain.set(encryptedString, key: key)
			let encryptedString = RNCryptor.encrypt(data: data, withPassword: AdamantSecret.keychainAppStorePassword).base64EncodedString()
		}
	}
	
	func remove(_ key: String) {
		try? keychain.remove(key)
	}
    
    func purgeStore() {
        try? keychain.removeAll()
        NotificationCenter.default.post(name: Notification.Name.SecuredStore.securedStorePurged, object: self)
    }
}
