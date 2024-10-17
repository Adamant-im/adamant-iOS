//
//  SecureStorageProtocol.swift
//  
//
//  Created by Stanislav Jelezoglo on 05.08.2024.
//

import Foundation

public protocol SecureStorageProtocol {
    func getPrivateKey() -> SecKey?
    func getPublicKey(privateKey: SecKey) -> SecKey?
    func encrypt(data: Data, publicKey: SecKey) -> Data?
    func decrypt(data: Data, privateKey: SecKey) -> Data?
}
