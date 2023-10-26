//
//  BtcWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension String.adamant {
    static let bitcoin = String.localized("AccountTab.Wallets.bitcoin_wallet", comment: "Account tab: Bitcoin wallet")
    
    static let sendBtc = String.localized("AccountTab.Row.SendBtc", comment: "Account tab: 'Send BTC tokens' button")
}

final class BtcWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamant.bitcoin
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendBtc)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "bitcoin:\(address)"
    }
}
