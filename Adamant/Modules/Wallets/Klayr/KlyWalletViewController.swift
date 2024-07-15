//
//  KlyWalletViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant {
    static var kly: String {
        String.localized("AccountTab.Wallets.kly_wallet", comment: "Account tab: Klayr wallet")
    }
    
    static var sendKly: String {
        String.localized("AccountTab.Row.SendKly", comment: "Account tab: 'Send KLY tokens' button")
    }
}

final class KlyWalletViewController: WalletViewControllerBase {
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendKly)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "klayr:\(address)"
    }
    
    override func setTitle() {
        walletTitleLabel.text = String.adamant.kly
    }
}
