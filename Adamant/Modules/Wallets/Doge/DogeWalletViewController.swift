//
//  DogeWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import CommonKit
import UIKit

extension String.adamant {
    static var sendDoge: String {
        String.localized("AccountTab.Row.SendDoge", comment: "Account tab: 'Send DOGE tokens' button")
    }
}

final class DogeWalletViewController: WalletViewControllerBase {
    override var walletName: String {
        String.localized("AccountTab.Wallets.doge", comment: "Account tab: Doge wallet")
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendDoge)
    }

    override func encodeForQr(address: String) -> String? {
        return "doge:\(address)"
    }
}
