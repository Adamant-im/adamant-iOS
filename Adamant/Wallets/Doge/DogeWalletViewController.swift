//
//  DogeWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant {
    static let doge = String.localized("AccountTab.Wallets.doge_wallet", comment: "Account tab: Doge wallet")
    
    static let sendDoge = String.localized("AccountTab.Row.SendDoge", comment: "Account tab: 'Send DOGE tokens' button")
}

class DogeWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamant.doge
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendDoge)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "doge:\(address)"
    }
}
