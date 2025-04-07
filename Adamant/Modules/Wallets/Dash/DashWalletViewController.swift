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
    
    static var secretDash: String {
        String.localized("SecretWallets.Dash.Secret", comment: "Account tab: Dash wallet")
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

    override func setTitle() {
        walletTitleLabel.text = makeTitle()
    }
    
    override func makeTitle() -> String {
        let index = secretWalletsViewModel.state.currentActiveIndex
        if index <= 0 {
            return String.adamant.dash
        }else {
            return String.adamant.secretDash + " \(index)"
        }
    }
}
