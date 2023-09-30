//
//  EthWalletService+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension EthWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transactionsList) as? EthTransactionsViewController else {
            fatalError("Can't get EthTransactionsViewController")
        }
        
        vc.walletService = self
        vc.ethWalletService = self
        return vc
    }
}
