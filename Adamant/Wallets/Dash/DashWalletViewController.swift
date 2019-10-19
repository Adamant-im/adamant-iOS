//
//  DashWalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension String.adamantLocalized {
    static let dash = NSLocalizedString("AccountTab.Wallets.dash_wallet", comment: "Account tab: Dash wallet")
    
    static let sendDash = NSLocalizedString("AccountTab.Row.SendDash", comment: "Account tab: 'Send Dash tokens' button")
}

class DashWalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamantLocalized.dash
    }
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.sendDash
    }
    
    override func encodeForQr(address: String) -> String? {
        return "dash:\(address)"
    }
}
