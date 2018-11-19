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
    
    static let sendAdm = NSLocalizedString("AccountTab.Row.SendAdm", comment: "Account tab: 'Send ADM tokens' button")
}

class AdmWalletViewController: WalletViewControllerBase {
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		walletTitleLabel.text = String.adamantLocalized.wallets.adamant
	}
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.wallets.sendAdm
    }
    
    override func encodeForQr(address: String) -> String? {
        return AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
    }
}
