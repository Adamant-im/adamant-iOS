//
//  NodeWithGroup.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

struct NodeWithGroup: Codable, Equatable {
    let group: NodeGroup
    var node: Node
}

extension NodeGroup {
    var name: String {
        switch self {
        case .btc:
            return BtcWalletService.tokenNetworkSymbol
        case .eth:
            return EthWalletService.tokenNetworkSymbol
        case .klyNode:
            return KlyWalletService.tokenNetworkSymbol
        case .klyService:
            return KlyWalletService.tokenNetworkSymbol
            + " " + .adamant.coinsNodesList.serviceNode
        case .doge:
            return DogeWalletService.tokenNetworkSymbol
        case .dash:
            return DashWalletService.tokenNetworkSymbol
        case .adm:
            return AdmWalletService.tokenNetworkSymbol
        }
    }
    
    var includeVersionTitle: Bool {
        switch self {
        case .btc, .klyNode, .klyService, .doge, .adm:
            return true
        case .eth, .dash:
            return false
        }
    }
}
