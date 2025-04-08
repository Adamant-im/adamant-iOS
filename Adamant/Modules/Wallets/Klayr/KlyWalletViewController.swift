//
//  KlyWalletViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import UIKit

extension String.adamant {
    static var sendKly: String {
        String.localized("AccountTab.Row.SendKly", comment: "Account tab: 'Send KLY tokens' button")
    }
}

final class KlyWalletViewController: WalletViewControllerBase {
    override var walletName: String {
        String.localized("AccountTab.Wallets.kly", comment: "Account tab: Klayr wallet")
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendKly)
    }

    override func encodeForQr(address: String) -> String? {
        return "klayr:\(address)"
    }
}
