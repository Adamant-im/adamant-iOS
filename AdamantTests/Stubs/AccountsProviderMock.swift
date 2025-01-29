//
//  AccountsProviderMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant

final class AccountsProviderMock: AccountsProvider {
    
    var invokedGetAccount = false
    var invokedGetAccountCount = 0
    var invokedGetAccountParameters: String?
    var stubbedGetAccountResult: Result<CoreDataAccount, Error>!
    
    func getAccount(byAddress address: String) async throws -> CoreDataAccount {
        invokedGetAccount = true
        invokedGetAccountCount += 1
        invokedGetAccountParameters = address
        return try stubbedGetAccountResult.get()
    }
    
    var invokedGetAccountPublicKey = false
    var invokedGetAccountPublicKeyCount = 0
    var invokedGetAccountPublicKeyParameters: (address: String, publicKey: String)?
    var stubbedGetAccountPublicKeyResult: CoreDataAccount!
    
    func getAccount(byAddress address: String, publicKey: String) async throws -> CoreDataAccount {
        invokedGetAccountPublicKey = true
        invokedGetAccountPublicKeyCount += 1
        invokedGetAccountPublicKeyParameters = (address, publicKey)
        
        return stubbedGetAccountPublicKeyResult
    }
    
    func hasAccount(address: String) async -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getDummyAccount(for address: String) async throws -> DummyAccount {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
