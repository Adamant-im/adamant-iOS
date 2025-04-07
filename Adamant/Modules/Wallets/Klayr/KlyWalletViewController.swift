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
    static var kly: String {
        String.localized("AccountTab.Wallets.kly_wallet", comment: "Account tab: Klayr wallet")
    }
    
    static var secretKLY: String {
        String.localized("SecretWallets.kly.Secret", comment: "Account tab: Klayr wallet")
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
        walletTitleLabel.text = makeTitle()
    }
    
    override func makeTitle() -> String{
        let index = secretWalletsViewModel.state.currentActiveIndex
        if index <= 0 {
            return String.adamant.secretKLY
        } else {
            return String.adamant.secretKLY + " \(index)"
        }
    }
}
