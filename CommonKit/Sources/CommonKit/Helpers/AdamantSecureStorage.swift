//
//  AdamantSecureStorage.swift
//
//
//  Created by Stanislav Jelezoglo on 02.08.2024.
//

import Foundation

final class AdamantSecureStorage: SecureStorageProtocol {
    let tag = "com.adamant.keys.id".data(using: .utf8)!
    
    func getPrivateKey() -> SecKey? {
        guard let existingKey = loadPrivateKey() else {
            return createAndStorePrivateKey()
        }
        
        return existingKey
    }
    
    func getPublicKey(privateKey: SecKey) -> SecKey? {
        SecKeyCopyPublicKey(privateKey)
    }
    
    func encrypt(data: Data, publicKey: SecKey) -> Data? {
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            data as CFData,
            nil
        ) else {
            return nil
        }
        
        return encryptedData as Data
    }
    
    func decrypt(data: Data, privateKey: SecKey) -> Data? {
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            data as CFData,
            nil
        ) else {
            return nil
        }
        
        return decryptedData as Data
    }
}

private extension AdamantSecureStorage {
    func loadPrivateKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return (item as! SecKey)
        }
        
        return nil
    }
    
    func createAndStorePrivateKey() -> SecKey? {
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlock,
            .privateKeyUsage,
            nil
        ) else { return nil }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access
            ]
        ]
        
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, nil) else {
            return nil
        }
        
        return privateKey
    }
}
