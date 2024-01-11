//
//  EthWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant.wallets {
    static let ethereum = String.localized("AccountTab.Wallets.ethereum_wallet", comment: "Account tab: Ethereum wallet")
    
    static let sendEth = String.localized("AccountTab.Row.SendEth", comment: "Account tab: 'Send ETH tokens' button")
}

final class EthWalletViewController: WalletViewControllerBase {
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.wallets.sendEth)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "ethereum:\(address)"
    }
    
    override func setTitle() {
        walletTitleLabel.text = String.adamant.wallets.ethereum
    }
}
