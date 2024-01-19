//
//  LskWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant {
    static var lisk: String {
        String.localized("AccountTab.Wallets.lisk_wallet", comment: "Account tab: Lisk wallet")
    }
    
    static var sendLsk: String {
        String.localized("AccountTab.Row.SendLsk", comment: "Account tab: 'Send LSK tokens' button")
    }
}

final class LskWalletViewController: WalletViewControllerBase {
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendLsk)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "lisk:\(address)"
    }
    
    override func setTitle() {
        walletTitleLabel.text = String.adamant.lisk
    }
}
