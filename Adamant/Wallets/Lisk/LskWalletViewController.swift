//
//  LskWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension String.adamantLocalized {
    static let lisk = NSLocalizedString("AccountTab.Wallets.lisk_wallet", comment: "Account tab: Lisk wallet")
    
    static let sendLsk = NSLocalizedString("AccountTab.Row.SendLsk", comment: "Account tab: 'Send LSK tokens' button")
}

class LskWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamantLocalized.lisk
    }
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.sendLsk
    }
}
