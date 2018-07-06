//
//  AdamantApi+Delegates.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
    static let Delegates = (
        root: "/api/delegates",
        getDelegates: "/api/delegates",
        getDelegatesWithVotes: "/api/accounts/delegates",
        getDelegatesCount: "/api/delegates/count"
    )
}

extension AdamantApiService {
    func getDelegates(limit: Int, offset: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getDelegates, queryItems: [URLQueryItem(name: "limit", value: String(limit)),URLQueryItem(name: "offset", value: String(offset))])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Delegate>>) in
            switch serverResponse {
            case .success(let delegates):
                if let delegates = delegates.collection {
                    completion(.success(delegates))
                } else {
                    completion(.failure(.serverError(error: "No delegates")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
