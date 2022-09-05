//
//  AdamantApi+Keys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
    func getPublicKey(
        byAddress address: String,
        completion: @escaping (ApiServiceResult<String>) -> Void
    ) {
        sendRequest(
            path: ApiCommands.Accounts.getPublicKey,
            queryItems: [URLQueryItem(name: "address", value: address)]
        ) { (serverResponse: ApiServiceResult<GetPublicKeyResponse>) in
            switch serverResponse {
            case .success(let response):
                if let publicKey = response.publicKey {
                    completion(.success(publicKey))
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
