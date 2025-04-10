//
//  EthWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import UIKit

extension String.adamant.wallets {
    static var sendEth: String {
        String.localized("AccountTab.Row.SendEth", comment: "Account tab: 'Send ETH tokens' button")
    }
}

final class EthWalletViewController: WalletViewControllerBase {
    override var walletName: String {
        String.localized("AccountTab.Wallets.ethereum", comment: "Account tab: Ethereum wallet")
    }
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.wallets.sendEth)
    }

    override func encodeForQr(address: String) -> String? {
        return "ethereum:\(address)"
    }
}
