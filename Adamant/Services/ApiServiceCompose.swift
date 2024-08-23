//
//  ApiServiceCompose.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct ApiServiceCompose: ApiServiceComposeProtocol {
    let btc: ApiServiceProtocol
    let eth: ApiServiceProtocol
    let klyNode: ApiServiceProtocol
    let klyService: ApiServiceProtocol
    let doge: ApiServiceProtocol
    let dash: ApiServiceProtocol
    let adm: ApiServiceProtocol
    let ipfs: ApiServiceProtocol
    
    func chosenFastestNodeId(group: NodeGroup) -> UUID? {
        getApiService(group: group).chosenFastestNodeId
    }
    
    func hasActiveNode(group: NodeGroup) -> Bool {
        getApiService(group: group).hasActiveNode
    }
    
    func healthCheck(group: NodeGroup) {
        getApiService(group: group).healthCheck()
    }
}

private extension ApiServiceCompose {
    func getApiService(group: NodeGroup) -> ApiServiceProtocol {
        switch group {
        case .btc:
            return btc
        case .eth:
            return eth
        case .klyNode:
            return klyNode
        case .klyService:
            return klyService
        case .doge:
            return doge
        case .dash:
            return dash
        case .adm:
            return adm
        case .ipfs:
            return ipfs
        case .infoService:
            return ipfs
        }
    }
}
