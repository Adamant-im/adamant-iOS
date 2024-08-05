//
//  AdamantSecureStorage.swift
//
//
//  Created by Stanislav Jelezoglo on 02.08.2024.
//

import Foundation

public struct AdamantSecureStorage: SecureStorageProtocol {
    private let tag = "com.adamant.keys.id".data(using: .utf8)!
    
    public init() { }
    
    public func getPrivateKey() -> SecKey? {
        loadPrivateKey() ?? createAndStorePrivateKey()
    }
    
    public func getPublicKey(privateKey: SecKey) -> SecKey? {
        SecKeyCopyPublicKey(privateKey)
    }
    
    public func encrypt(data: Data, publicKey: SecKey) -> Data? {
        SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            data as CFData,
            nil
        ).map { $0 as Data }
    }
    
    public func decrypt(data: Data, privateKey: SecKey) -> Data? {
        SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            data as CFData,
            nil
        ).map { $0 as Data }
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
        
        return status == errSecSuccess
        ? (item as! SecKey)
        : nil
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
        
        return SecKeyCreateRandomKey(attributes as CFDictionary, nil)
    }
}
