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
    
    static let sendEth = NSLocalizedString("AccountTab.Row.SendEth", comment: "Account tab: 'Send ETH tokens' button")
}

class EthWalletViewController: WalletViewControllerBase {
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = String.adamantLocalized.wallets.ethereum
	}
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.wallets.sendEth
    }
    
    override func encodeForQr(address: String) -> String? {
        return "ethereum:\(address)"
    }
}
