//
//  EthWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class EthWalletViewController: WalletViewControllerBase {
	// MARK: - Properties
	
	var service: EthWalletService!
	override var height: CGFloat { return 100 }
	
	
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = "Ethereum Wallet"
	}
}
