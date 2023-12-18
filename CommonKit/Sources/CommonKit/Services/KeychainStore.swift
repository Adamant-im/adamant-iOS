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

public final class KeychainStore: SecuredStore {
    // MARK: - Properties
    private static let keychain = Keychain(service: "\(AdamantSecret.appIdentifierPrefix).im.adamant.messenger")
    
    public init() {}
    
    // MARK: - SecuredStore
    
    public func get<T: Decodable>(_ key: String) -> T? {
        guard !(T.self == String.self) else { return getString(key) as? T }
        
        guard
            let raw = getString(key),
            let data = raw.data(using: .utf8)
        else { return nil }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    public func set<T: Encodable>(_ value: T, for key: String) {
        if let string = value as? String {
            setString(string, for: key)
            return
        }
        
        guard let data = try? JSONEncoder().encode(value) else { return }
        String(data: data, encoding: .utf8).map { setString($0, for: key) }
    }
    
    public func remove(_ key: String) {
        try? KeychainStore.keychain.remove(key)
    }
    
    public func purgeStore() {
        try? KeychainStore.keychain.removeAll()
        NotificationCenter.default.post(name: Notification.Name.SecuredStore.securedStorePurged, object: self)
    }
    
    // MARK: - Tools
    
    private func getString(_ key: String) -> String? {
        guard let encryptedValue = KeychainStore.keychain[key],
            let decryptedValue = KeychainStore.decrypt(string: encryptedValue, password: AdamantSecret.keychainValuePassword) else {
                return nil
        }

        return decryptedValue
    }

    private func setString(_ value: String, for key: String) {
        guard let encryptedValue = KeychainStore.encrypt(string: value, password: AdamantSecret.keychainValuePassword) else {
            return
        }

        try? KeychainStore.keychain.set(encryptedValue, key: key)
    }
    
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
    
    public static func migrateIfNeeded() {
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
