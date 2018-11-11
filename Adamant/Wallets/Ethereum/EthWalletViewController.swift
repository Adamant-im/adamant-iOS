//
//  EthWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension String.adamantLocalized.wallets {
    static let ethereum = NSLocalizedString("AccountTab.Wallets.ethereum_wallet", comment: "Account tab: Ethereum wallet")
}

class EthWalletViewController: WalletViewControllerBase {
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = String.adamantLocalized.wallets.ethereum
	}
}
