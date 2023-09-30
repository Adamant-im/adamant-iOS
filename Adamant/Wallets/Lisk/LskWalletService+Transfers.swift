//
//  LskWalletService+Transfers.swift
//  Adamant
//
//  Created by Anton Boyarkin on 28/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension LskWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.transactionsList) as? LskTransactionsViewController else {
            fatalError("Can't get LskTransactionsViewController")
        }
        
        vc.walletService = self
        vc.lskWalletService = self
        return vc
    }
}
