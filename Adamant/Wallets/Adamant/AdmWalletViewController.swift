//
//  AdmWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension String.adamantLocalized.wallets {
    static let adamant = NSLocalizedString("AccountTab.Wallets.adamant_wallet", comment: "Account tab: Adamant wallet")
}

class AdmWalletViewController: WalletViewControllerBase {
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = String.adamantLocalized.wallets.adamant
	}
}
