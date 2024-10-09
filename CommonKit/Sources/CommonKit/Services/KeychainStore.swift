//
//  KeychainStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
@preconcurrency import KeychainAccess
import RNCryptor
import CryptoKit

public final class KeychainStore: SecuredStore, @unchecked Sendable {
    // MARK: - Properties
    private static let keychain = Keychain(service: "\(AdamantSecret.appIdentifierPrefix).im.adamant.messenger")
    
    private let secureStorage: SecureStorageProtocol
    
    private let keychainStoreIdAlias = "com.adamant.messenger.id"
    private var keychainPassword: String?
    
    private let oldKeychainService = "im.adamant"
    private let migrationKey = "migrated"
    private let migrationValue = "2"
    private lazy var userDefaults = UserDefaults(suiteName: sharedGroup)
    
    public init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
        
        migrateUserDefaultsIfNeeded()
        clearIfNeeded()
        configure()
        migrateIfNeeded()
    }
    
    // MARK: - SecuredStore
    
    public func get<T: Decodable>(_ key: String) -> T? {
        guard let data = getValue(key) else { return nil }
        
        guard !(T.self == String.self) else {
            return String(data: data, encoding: .utf8) as? T
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    public func set<T: Encodable>(_ value: T, for key: String) {
        if let string = value as? String,
           let data = string.data(using: .utf8) {
            setValue(data, for: key)
            return
        }
        
        guard let data = try? JSONEncoder().encode(value) else { return }
        setValue(data, for: key)
    }
    
    public func remove(_ key: String) {
        try? KeychainStore.keychain.remove(key)
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
            )
            
            keychainPassword = decryptedData?.base64EncodedString()
            return
        }
        
        let keychainRandomKeyData = SymmetricKey(size: .bits256)
            .withUnsafeBytes { Data($0) }
        let keychainRandomKey = keychainRandomKeyData.base64EncodedString()
        
        guard let encryptedData = secureStorage.encrypt(
            data: keychainRandomKeyData,
            publicKey: publicKey
        ) else { return }
        
        keychainPassword = keychainRandomKey
        setData(encryptedData, for: keychainStoreIdAlias)
    }
    
    func clearIfNeeded() {
        guard let userDefaults = userDefaults else { return }
        
        let isFirstRun = !userDefaults.bool(forKey: firstRun)
        
        guard isFirstRun else { return }
        
        userDefaults.set(true, forKey: firstRun)
        
        purgeStore()
    }
    
    func getValue(_ key: String) -> Data? {
        guard let keychainPassword = keychainPassword,
              let data = getData(for: key)
        else { return nil}
        
        return decrypt(
            data: data,
            password: keychainPassword
        )
    }
    
    func setValue(_ value: Data, for key: String) {
        guard let keychainPassword = keychainPassword else {
            return
        }
        
        let encryptedValue = encrypt(
            data: value,
            password: keychainPassword
        )
        
        setData(encryptedValue, for: key)
    }
    
    func getData(for key: String) -> Data? {
        try? KeychainStore.keychain.getData(key)
    }
    
    func setData(_ value: Data, for key: String) {
        try? KeychainStore.keychain.set(value, key: key)
    }
    
    func encrypt(
        data: Data,
        password: String
    ) -> Data {
        RNCryptor.encrypt(
            data: data,
            withPassword: password
        )
    }
    
    func decrypt(
        data: Data,
        password: String
    ) -> Data? {
        try? RNCryptor.decrypt(data: data, withPassword: password)
    }
    
    func decryptOld(
        string: String,
        password: String
    ) -> Data? {
        guard let encryptedData = Data(base64Encoded: string) else {
            return nil
        }
        return try? RNCryptor.decrypt(data: encryptedData, withPassword: password)
    }
    
    func purgeStore() {
        try? KeychainStore.keychain.removeAll()
        NotificationCenter.default.post(name: Notification.Name.SecuredStore.securedStorePurged, object: self)
    }
}

private extension KeychainStore {
    // MARK: - Migration
    
    /*
     * Long time ago, we didn't use shared keychain. Now we do. We need to move all items from old keychain to new. And drop old one.
     */
    
    func migrateIfNeeded() {
        let migrated = KeychainStore.keychain[migrationKey]
        
        guard keychainPassword != nil,
              migrated != migrationValue
        else { return }
        
        let oldKeychain = Keychain(service: oldKeychainService)
        
        migrate(
            keychain: oldKeychain,
            oldPassword: AdamantSecret.oldKeychainPass
        )
        
        migrate(
            keychain: KeychainStore.keychain,
            oldPassword: AdamantSecret.keychainValuePassword
        )
        
        try? KeychainStore.keychain.set(migrationValue, key: migrationKey)
        try? oldKeychain.removeAll()
    }
    
    func migrate(
        keychain: Keychain,
        oldPassword: String
    ) {
        for key in keychain.allKeys() {
            guard key != keychainStoreIdAlias,
                  let oldEncryptedValue = keychain[key],
                  let value = decryptOld(
                    string: oldEncryptedValue,
                    password: oldPassword
                  )
            else { continue }
            
            try? KeychainStore.keychain.remove(key)
            setValue(value, for: key)
        }
    }
    
    func migrateUserDefaultsIfNeeded() {
        let migrated = KeychainStore.keychain[migrationKey]
        guard migrated != migrationValue else { return }
        
        let value = UserDefaults.standard.bool(forKey: firstRun)
        userDefaults?.set(value, forKey: firstRun)
    }
}

private let firstRun = "app.firstRun"
private let sharedGroup = "group.adamant.adamant-messenger"
