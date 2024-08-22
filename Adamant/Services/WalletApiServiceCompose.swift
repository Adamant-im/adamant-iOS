//
//  WalletApiServiceCompose.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct WalletApiServiceCompose: WalletApiServiceComposeProtocol {
    let btc: WalletApiService
    let eth: WalletApiService
    let klyNode: WalletApiService
    let klyService: WalletApiService
    let doge: WalletApiService
    let dash: WalletApiService
    let adm: WalletApiService
    let ipfs: WalletApiService
    
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

private extension WalletApiServiceCompose {
    func getApiService(group: NodeGroup) -> WalletApiService {
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
        }
    }
}
