//
//  CoinsNodesListViewModel+Wallets.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

extension CoinsNodesListViewModel {
    struct ApiServices {
        let btc: WalletApiService
        let eth: WalletApiService
        let klyNode: WalletApiService
        let klyService: WalletApiService
        let doge: WalletApiService
        let dash: WalletApiService
        let adm: WalletApiService
    }
}

extension CoinsNodesListViewModel.ApiServices {
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
        }
    }
}
