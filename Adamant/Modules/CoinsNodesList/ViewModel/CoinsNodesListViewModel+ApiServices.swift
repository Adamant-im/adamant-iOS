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
        let lskNode: WalletApiService
        let lskService: WalletApiService
        let doge: WalletApiService
        let dash: WalletApiService
        let adm: WalletApiService
        let ipfs: WalletApiService
    }
}

extension CoinsNodesListViewModel.ApiServices {
    func getApiService(group: NodeGroup) -> WalletApiService {
        switch group {
        case .btc:
            return btc
        case .eth:
            return eth
        case .lskNode:
            return lskNode
        case .lskService:
            return lskService
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
