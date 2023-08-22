//
//  AdamantApi+Accounts.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension AdamantApiService.ApiCommands {
    static let Accounts = (
        root: "/api/accounts",
        getPublicKey: "/api/accounts/getPublicKey",
        newAccount: "/api/accounts/new"
    )
}

// MARK: - Accounts
extension AdamantApiService {
    /// Get account by passphrase.
    func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        // MARK: 1. Get keypair from passphrase
        guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
            completion(.failure(.accountNotFound))
            return
        }
        
        // MARK: 2. Send
        getAccount(byPublicKey: keypair.publicKey, completion: completion)
    }
    
    /// Get account by publicKey
    func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        sendRequest(
            path: ApiCommands.Accounts.root,
            queryItems: [URLQueryItem(name: "publicKey", value: publicKey)],
            completion: makeCompletionWrapper(publicKey: publicKey, completion: completion)
        )
    }
    
    /// Get account by publicKey
    func getAccount(byPublicKey publicKey: String) async throws -> AdamantAccount {
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<AdamantAccount, Error>) in
            sendRequest(
                path: ApiCommands.Accounts.root,
                queryItems: [URLQueryItem(name: "publicKey", value: publicKey)],
                completion: makeCompletionWrapper(publicKey: publicKey) { response in
                    switch response {
                    case .success(let t):
                        continuation.resume(returning: t)
                    case .failure(let apiServiceError):
                        continuation.resume(throwing: apiServiceError)
                    }
                }
            )
        }
    }

    func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        sendRequest(
            path: ApiCommands.Accounts.root,
            queryItems: [URLQueryItem(name: "address", value: address)],
            completion: makeCompletionWrapper(publicKey: nil, completion: completion)
        )
    }
    
    func getAccount(byAddress address: String) async throws -> AdamantAccount {
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<AdamantAccount, Error>) in
            sendRequest(
                path: ApiCommands.Accounts.root,
                queryItems: [URLQueryItem(name: "address", value: address)],
                completion: makeCompletionWrapper(publicKey: nil) { response in
                    switch response {
                    case .success(let t):
                        continuation.resume(returning: t)
                    case .failure(let apiServiceError):
                        continuation.resume(throwing: apiServiceError)
                    }
                }
            )
        }
    }
}

private func makeCompletionWrapper(
    publicKey: String?,
    completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void
) -> (ApiServiceResult<ServerModelResponse<AdamantAccount>>) -> Void {
    { serverResponse in
        switch serverResponse {
        case .success(let response):
            if let model = response.model {
                completion(.success(model))
                return
            }
            
            let error = AdamantApiService.translateServerError(response.error)
            guard let publicKey = publicKey, error == .accountNotFound else {
                completion(.failure(error))
                return
            }
            
            completion(.success(.makeEmptyAccount(publicKey: publicKey)))
        case .failure(let error):
            completion(.failure(.networkError(error: error)))
        }
    }
}
