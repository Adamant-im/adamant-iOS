//
//  ApiServiceCompose.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import Foundation

struct ApiServiceCompose: ApiServiceComposeProtocol {
    let btc: ApiServiceProtocol
    let eth: ApiServiceProtocol
    let klyNode: ApiServiceProtocol
    let klyService: ApiServiceProtocol
    let doge: ApiServiceProtocol
    let dash: ApiServiceProtocol
    let adm: ApiServiceProtocol
    let ipfs: ApiServiceProtocol
    let infoService: ApiServiceProtocol

    func get(_ group: NodeGroup) -> ApiServiceProtocol? {
        getApiService(group: group)
    }
}

extension ApiServiceCompose {
    fileprivate func getApiService(group: NodeGroup) -> ApiServiceProtocol {
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
            return infoService
        }
    }
}
