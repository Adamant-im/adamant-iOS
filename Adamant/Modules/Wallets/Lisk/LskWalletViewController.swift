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
    static let lisk = String.localized("AccountTab.Wallets.lisk_wallet", comment: "Account tab: Lisk wallet")
    
    static let sendLsk = String.localized("AccountTab.Row.SendLsk", comment: "Account tab: 'Send LSK tokens' button")
}

final class LskWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamant.lisk
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendLsk)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "lisk:\(address)"
    }
}
