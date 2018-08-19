//
//  AdmWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class AdmWalletViewController: WalletViewControllerBase {
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = "Adamant Wallet"
	}
}
