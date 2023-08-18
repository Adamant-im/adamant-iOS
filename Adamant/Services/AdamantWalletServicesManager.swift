//
//  AdamantWalletServicesManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

final class AdamantWalletServicesManager: WalletServicesManager {
    let admWalletService = AdmWalletService()
    let btcWalletService = BtcWalletService()
    let ethWalletService = EthWalletService()
    let dogeWalletService = DogeWalletService()
    let dashWalletService = DashWalletService()
    
    let lskWalletService = LskWalletService(
        mainnet: true,
        nodes: LskWalletService.nodes,
        services: LskWalletService.serviceNodes
    )
    
    let erc20WalletServices = ERC20Token.supportedTokens.map {
        ERC20WalletService(token: $0)
    }
    
    nonisolated init() {}
}
