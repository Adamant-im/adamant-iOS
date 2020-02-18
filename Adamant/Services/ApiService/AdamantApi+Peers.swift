//
//  AdamantApi+Peers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
    static let Peers = (
        root: "/api/peers",
        version: "/api/peers/version"
    )
}


// MARK: - Peers
extension AdamantApiService {
    func getNodeVersion(url: URL, completion: @escaping (ApiServiceResult<NodeVersion>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(url: url, subpath: ApiCommands.Peers.version)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<NodeVersion>) in
            switch serverResponse {
            case .success(let version):
                completion(.success(version))
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
