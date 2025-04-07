//
//  BtcWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import CommonKit
import UIKit

extension String.adamant {
    static var bitcoin: String {
        String.localized("AccountTab.Wallets.bitcoin_wallet", comment: "Account tab: Bitcoin wallet")
    }
    
    static var secretBitcoin: String {
        String.localized("SecretWallets.Bitcoin.Secret", comment: "Secret wallets: Bitcoin")
    }
    
    static var sendBtc: String {
        String.localized("AccountTab.Row.SendBtc", comment: "Account tab: 'Send BTC tokens' button")
    }
}

final class BtcWalletViewController: WalletViewControllerBase {

    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendBtc)
    }

    override func encodeForQr(address: String) -> String? {
        return "bitcoin:\(address)"
    }

    override func setTitle() {
        walletTitleLabel.text = makeTitle()
    }
    
    override func makeTitle() -> String {
        let index = secretWalletsViewModel.state.currentActiveIndex
        if index <= 0 {
            return String.adamant.bitcoin
        } else {
            return String.adamant.secretBitcoin + " \(index)"
        }
    }
}
