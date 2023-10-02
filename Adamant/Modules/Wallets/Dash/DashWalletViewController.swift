//
//  DashWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit

extension String.adamant {
    static let dash = String.localized("AccountTab.Wallets.dash_wallet", comment: "Account tab: Dash wallet")
    
    static let sendDash = String.localized("AccountTab.Row.SendDash", comment: "Account tab: 'Send Dash tokens' button")
}

final class DashWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamant.dash
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: String.adamant.sendDash)
    }
    
    override func encodeForQr(address: String) -> String? {
        return "dash:\(address)"
    }
}
