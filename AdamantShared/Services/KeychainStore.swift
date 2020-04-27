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
    // MARK: - Properties
    private static let keychain = Keychain(service: "\(AdamantSecret.appIdentifierPrefix).im.adamant.messenger")
    
    // MARK: - SecuredStore
    
    func get(_ key: String) -> String? {
        guard let encryptedValue = KeychainStore.keychain[key],
            let decryptedValue = KeychainStore.decrypt(string: encryptedValue, password: AdamantSecret.keychainValuePassword) else {
                return nil
        }

        return decryptedValue
    }
    
    func getArray(_ key: String) -> [String]? {
        guard let encryptedValue = KeychainStore.keychain[key],
            let decryptedValue = KeychainStore.decrypt(string: encryptedValue, password: AdamantSecret.keychainValuePassword), let data = decryptedValue.data(using: .utf8) else {
                return nil
        }
        
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("FAIL to decode array from keychain")
        }

        return nil
    }

    func set(_ value: String, for key: String) {
        guard let encryptedValue = KeychainStore.encrypt(string: value, password: AdamantSecret.keychainValuePassword) else {
            return
        }

        try? KeychainStore.keychain.set(encryptedValue, key: key)
    }
    
    func set(_ value: [String], for key: String) {
        var strValue = ""
        do {
            let data = try JSONEncoder().encode(value)
            strValue = String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("FAIL to encode array from keychain")
            return
        }
        
        guard let encryptedValue = KeychainStore.encrypt(string: strValue, password: AdamantSecret.keychainValuePassword) else {
            return
        }

        try? KeychainStore.keychain.set(encryptedValue, key: key)
    }
    
    func remove(_ key: String) {
        try? KeychainStore.keychain.remove(key)
    }
    
    func purgeStore() {
        try? KeychainStore.keychain.removeAll()
        NotificationCenter.default.post(name: Notification.Name.SecuredStore.securedStorePurged, object: self)
    }
    
    
    // MARK: - Tools
    
    private static func encrypt(string: String, password: String, encoding: String.Encoding = .utf8) -> String? {
        guard let data = string.data(using: encoding) else {
            return nil
        }
        
        return RNCryptor.encrypt(data: data, withPassword: password).base64EncodedString()
    }
    
    private static func decrypt(string: String, password: String, encoding: String.Encoding = .utf8) -> String? {
        if let encryptedData = Data(base64Encoded: string),
            let data = try? RNCryptor.decrypt(data: encryptedData, withPassword: password),
            let string = String(data: data, encoding: encoding) {
            return string
        }
        
        return nil
    }
    
    // MARK: - Migration
    
    /*
     * Long time ago, we didn't use shared keychain. Now we do. We need to move all items from old keychain to new. And drop old one.
     */
    private static let oldKeychainService = "im.adamant"
    private static let migrationKey = "migrated"
    private static let migrationValue = "1"
    
    static func migrateIfNeeded() {
        // Check flag
        if let migrated = KeychainStore.keychain[migrationKey], migrated == migrationValue {
            return
        }
        
        // Get old keychain
        let oldKeychain = Keychain(service: KeychainStore.oldKeychainService)
        for key in oldKeychain.allKeys() {
            // Get value, decode with old pass
            guard let oldEncryptedValue = oldKeychain[key], let value = decrypt(string: oldEncryptedValue, password: AdamantSecret.oldKeychainPass) else {
                continue
            }
            
            // Encode value and key with new pass
            guard let encryptedValue = encrypt(string: value, password: AdamantSecret.keychainValuePassword) else {
                continue
            }
            
            try? KeychainStore.keychain.set(encryptedValue, key: key)
        }
        
        // Set flag
        try? KeychainStore.keychain.set(migrationValue, key: migrationKey)
        // Drop old keychain
        try? oldKeychain.removeAll()
    }
}
