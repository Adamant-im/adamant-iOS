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
    
    private let secureStorage: SecureStorageProtocol = AdamantSecureStorage()
    private let keychainStoreIdAlias = "com.adamant.messenger.id"
    private var keychainPassword: String?
    
    private let oldKeychainService = "im.adamant"
    private let migrationKey = "migrated"
    private let migrationValue = "2"
    
    public init() {
        configure()
        migrateIfNeeded()
    }
    
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
}

private extension KeychainStore {
    func configure() {
        guard let privateKey = secureStorage.getPrivateKey(),
              let publicKey = secureStorage.getPublicKey(privateKey: privateKey)
        else { return }
                
        if let savedKey = getData(for: keychainStoreIdAlias) {
            let decryptedData = secureStorage.decrypt(
                data: savedKey,
                privateKey: privateKey
            ) ?? Data()
            
            keychainPassword = String(data: decryptedData, encoding: .utf8)
            return
        }
        
        let randomID = String.random(length: 32)
        
        guard let data = randomID.data(using: .utf8),
              let encryptedData = secureStorage.encrypt(data: data, publicKey: publicKey)
        else { return }
        
        keychainPassword = randomID
        setData(encryptedData, for: keychainStoreIdAlias)
    }
    
    func getString(_ key: String) -> String? {
        guard let keychainPassword = keychainPassword,
              let value = KeychainStore.keychain[key] else {
            return nil
        }
        
        let decryptedValue = decrypt(
            string: value,
            password: keychainPassword
        )
        
        return decryptedValue
    }
    
    func setString(_ value: String, for key: String) {
        guard let keychainPassword = keychainPassword,
              let encryptedValue = encrypt(
                string: value,
                password: keychainPassword
              )
        else {
            return
        }
        
        try? KeychainStore.keychain.set(encryptedValue, key: key)
    }
    
    func getData(for key: String) -> Data? {
        try? KeychainStore.keychain.getData(key)
    }
    
    func setData(_ value: Data, for key: String) {
        try? KeychainStore.keychain.set(value, key: key)
    }
    
    func encrypt(
        string: String,
        password: String,
        encoding: String.Encoding = .utf8
    ) -> String? {
        guard let data = string.data(using: encoding) else {
            return nil
        }
        
        return RNCryptor.encrypt(
            data: data,
            withPassword: password
        ).base64EncodedString()
    }
    
    func decrypt(
        string: String,
        password: String,
        encoding: String.Encoding = .utf8
    ) -> String? {
        if let encryptedData = Data(base64Encoded: string),
            let data = try? RNCryptor.decrypt(data: encryptedData, withPassword: password),
            let string = String(data: data, encoding: encoding) {
            return string
        }
        
        return nil
    }
}

private extension KeychainStore {
    // MARK: - Migration
    
    /*
     * Long time ago, we didn't use shared keychain. Now we do. We need to move all items from old keychain to new. And drop old one.
     */
    
    func migrateIfNeeded() {
        let migrated = KeychainStore.keychain[migrationKey]
        
        guard let keychainPassword = keychainPassword,
              migrated != migrationValue
        else { return }
        
        let oldKeychain = Keychain(service: oldKeychainService)
        
        migrate(
            keychain: oldKeychain,
            oldPassword: AdamantSecret.oldKeychainPass,
            newPassword: keychainPassword
        )
        
        migrate(
            keychain: KeychainStore.keychain,
            oldPassword: AdamantSecret.keychainValuePassword,
            newPassword: keychainPassword
        )
        
        try? KeychainStore.keychain.set(migrationValue, key: migrationKey)
        try? oldKeychain.removeAll()
    }
    
    func migrate(
        keychain: Keychain,
        oldPassword: String,
        newPassword: String
    ) {
        for key in keychain.allKeys() {
            guard key != keychainStoreIdAlias,
                  let oldEncryptedValue = keychain[key],
                  let value = decrypt(
                    string: oldEncryptedValue,
                    password: oldPassword
                  ),
                  let encryptedValue = encrypt(
                      string: value,
                      password: newPassword
                  )
            else { continue }
            
            try? KeychainStore.keychain.set(encryptedValue, key: key)
        }
    }
}
