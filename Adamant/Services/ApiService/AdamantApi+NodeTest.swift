//
//  AdamantApi+NodeTest.swift
//  Adamant
//
//  Created by Андрей on 23.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
    func testNode(
        node: Node,
        completion: @escaping (ApiServiceResult<TimeInterval>) -> Void
    ) {
        guard let nodeURL = node.asURL() else {
            completion(
                .failure(InternalError.endpointBuildFailed.apiServiceErrorWith(error: nil))
            )
            return
        }
        
        let startTimestamp = Date().timeIntervalSince1970
        
        getNodeStatus(url: nodeURL) { result in
            switch result {
            case .success(let status):
                let ping = Date().timeIntervalSince1970 - startTimestamp
                
                guard let height = status.network?.height else {
                    completion(
                        .failure(InternalError.nodeTestFailed.apiServiceErrorWith(error: nil))
                    )
                    return
                }
                
                node.height = height
                
                guard status.wsClient?.enabled ?? false else {
                    completion(
                        .failure(InternalError.nodeTestFailed.apiServiceErrorWith(error: nil))
                    )
                    return
                }
                
                completion(.success(ping))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
