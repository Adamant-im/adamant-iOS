//
//  AdamantApi+Accounts.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public extension ApiCommands {
    static let Accounts = (
        root: "/api/accounts",
        getPublicKey: "/api/accounts/getPublicKey",
        newAccount: "/api/accounts/new"
    )
}

// MARK: - Accounts
extension AdamantApiService {
    /// Get account by passphrase.
    public func getAccount(byPassphrase passphrase: String) async -> ApiServiceResult<AdamantAccount> {
        guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase, password: String.empty) else {
            return .failure(.accountNotFound)
        }
        
        return await getAccount(byPublicKey: keypair.publicKey)
    }
    
    /// Get account by publicKey
    public func getAccount(byPublicKey publicKey: String) async -> ApiServiceResult<AdamantAccount> {
        switch await request({ apiCore, origin in
            let response: ApiServiceResult<ServerModelResponse<AdamantAccount>> = await apiCore.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Accounts.root,
                method: .get,
                parameters: ["publicKey": publicKey],
                encoding: .url
            )
            
            return response.flatMap { $0.resolved() }
        }) {
        case let .success(value):
            return .success(value)
        case let .failure(error):
            switch error {
            case .accountNotFound:
                return .success(.makeEmptyAccount(publicKey: publicKey))
            default:
                return .failure(error)
            }
        }
    }

    public func getAccount(byAddress address: String) async -> ApiServiceResult<AdamantAccount> {
        await request { apiCore, origin in
            let response: ApiServiceResult<
                ServerModelResponse<AdamantAccount>
            > = await apiCore.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Accounts.root,
                method: .get,
                parameters: ["address": address],
                encoding: .url
            )
            
            return response.flatMap { $0.resolved() }
        }
    }
}
