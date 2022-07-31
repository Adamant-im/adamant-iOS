//
//  AdamantApi+Status.swift
//  Adamant
//
//  Created by Андрей on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
    static let status = "/api/node/status"
}

extension AdamantApiService {
    func getNodeStatus(
        url: URL,
        completion: @escaping (ApiServiceResult<NodeStatus>) -> Void
    ) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(url: url, path: ApiCommands.status)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(
            url: endpoint,
            method: .get,
            encoding: .json,
            headers: headers
        ) { (serverResponse: ApiServiceResult<NodeStatus>) in
            switch serverResponse {
            case .success(let status):
                completion(.success(status))
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
