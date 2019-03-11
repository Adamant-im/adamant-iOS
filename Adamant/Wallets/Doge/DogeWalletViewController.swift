//
//  DogeWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

extension String.adamantLocalized {
    static let doge = NSLocalizedString("AccountTab.Wallets.doge_wallet", comment: "Account tab: Doge wallet")
    
    static let sendDoge = NSLocalizedString("AccountTab.Row.SendDoge", comment: "Account tab: 'Send DOGE tokens' button")
}

class DogeWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamantLocalized.doge
    }
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.sendDoge
    }
    
    override func encodeForQr(address: String) -> String? {
        return "doge:\(address)"
    }
}
