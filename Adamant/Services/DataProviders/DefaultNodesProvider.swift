//
//  DefaultNodesProvider.swift
//  Adamant
//
//  Created by Andrew G on 08.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit

struct DefaultNodesProvider {
    var nodes: [NodeGroup: [Node]] {
        .init(uniqueKeysWithValues: NodeGroup.allCases.map {
            ($0, defaultItems(group: $0))
        })
    }
}

private extension DefaultNodesProvider {
    func defaultItems(group: NodeGroup) -> [Node] {
        switch group {
        case .btc:
            return BtcWalletService.nodes
        case .eth:
            return EthWalletService.nodes
        case .klyNode:
            return KlyWalletService.nodes
        case .klyService:
            return KlyWalletService.serviceNodes
        case .doge:
            return DogeWalletService.nodes
        case .dash:
            return DashWalletService.nodes
        case .adm:
            return AdmWalletService.nodes
        case .ipfs:
            return IPFSApiService.nodes
        case .infoService:
            return [.makeDefaultNode(url: .init(string: AdamantResources.coinsInfoService)!)]
        }
    }
}
