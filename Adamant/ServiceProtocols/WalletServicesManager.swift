//
//  WalletServicesManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

@MainActor
protocol WalletServicesManager: AnyObject {
    var admWalletService: AdmWalletService { get }
    var btcWalletService: BtcWalletService { get }
    var ethWalletService: EthWalletService { get }
    var dogeWalletService: DogeWalletService { get }
    var dashWalletService: DashWalletService { get }
    var lskWalletService: LskWalletService { get }
    var erc20WalletServices: [ERC20WalletService] { get }
}

extension WalletServicesManager {
    var wallets: [WalletService] {
        [
            admWalletService,
            btcWalletService,
            ethWalletService,
            dogeWalletService,
            dashWalletService,
            lskWalletService
        ] + erc20WalletServices
    }
    
    var thirdPartyWallets: [WalletService] {
        [
            btcWalletService,
            ethWalletService,
            dogeWalletService,
            dashWalletService,
            lskWalletService
        ] + erc20WalletServices
    }
    
    func getService(richType: String) -> WalletService? {
        wallets.first { $0.richMessageType == richType }
    }
}
