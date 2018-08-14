//
//  WalletsRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 14.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
	struct Wallets {
		static let EthereumWallet = AdamantScene(identifier: "EthWalletViewController") { r in
			let c = EthWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
			c.dialogService = r.resolve(DialogService.self)
			return c
		}
	}
}
