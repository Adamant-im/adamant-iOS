//
//  DashWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import UIKit

extension String.adamant {
    static var dash: String {
        String.localized("AccountTab.Wallets.dash_wallet", comment: "Account tab: Dash wallet")
    }
    
    static var sendDash: String {
        String.localized("AccountTab.Row.SendDash", comment: "Account tab: 'Send Dash tokens' button")
    }
}

final class DashWalletViewController: WalletViewControllerBase {
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendDash)
    }

    override func encodeForQr(address: String) -> String? {
        return "dash:\(address)"
    }
}
