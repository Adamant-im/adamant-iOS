//
//  AdamantApi+Accounts.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
    static let Accounts = (
        root: "/api/accounts",
        getPublicKey: "/api/accounts/getPublicKey",
        newAccount: "/api/accounts/new"
    )
}

// MARK: - Accounts
extension AdamantApiService {
    
    /// Create new account with publicKey
    func newAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        
        // MARK: 1. Prepare params
        let params = [
            "publicKey": publicKey
        ]
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Send
        sendRequest(
            path: ApiCommands.Accounts.newAccount,
            method: .post,
            parameters: params,
            encoding: .json,
            headers: headers
        ) { (serverResponse: ApiServiceResult<ServerModelResponse<AdamantAccount>>) in
            switch serverResponse {
            case .success(let response):
                if let model = response.model {
                    completion(.success(model))
                } else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    /// Get existing account by passphrase.
    func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        // MARK: 1. Get keypair from passphrase
        guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
            completion(.failure(.accountNotFound))
            return
        }
        
        // MARK: 2. Send
        getAccount(byPublicKey: keypair.publicKey, completion: completion)
    }
    
    /// Get existing account by publicKey
    func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        sendRequest(
            path: ApiCommands.Accounts.root,
            queryItems: [URLQueryItem(name: "publicKey", value: publicKey)]
        ) { (serverResponse: ApiServiceResult<ServerModelResponse<AdamantAccount>>) in
            switch serverResponse {
            case .success(let response):
                if let model = response.model {
                    completion(.success(model))
                } else {
                    let err = AdamantApiService.translateServerError(response.error)
                    completion(.failure(err))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {
        sendRequest(
            path: ApiCommands.Accounts.root,
            queryItems: [URLQueryItem(name: "address", value: address)]
        ) { (serverResponse: ApiServiceResult<ServerModelResponse<AdamantAccount>>) in
            switch serverResponse {
            case .success(let response):
                if let model = response.model {
                    completion(.success(model))
                } else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
