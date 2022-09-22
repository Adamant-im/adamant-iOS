//
//  ERC20WalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension String.adamantLocalized.wallets {
    enum erc20 {
        static func tokenWallet(_ token: String) -> String {
            return String(format: NSLocalizedString("AccountTab.Wallets.erc20_wallet", comment: "Account tab: Ethereum wallet"), token)
        }
        
        static func sendToken(_ token: String) -> String {
            return String(format: NSLocalizedString("AccountTab.Row.SendToken", comment: "Account tab: 'Send ERC20 tokens' button"), token)
        }
    }
}

class ERC20WalletViewController: WalletViewControllerBase {
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamantLocalized.wallets.erc20.tokenWallet(service?.tokenName ?? "")
    }
    
    override func sendRowLocalizedLabel() -> NSAttributedString {
        let networkSymbol = service?.tokenNetworkSymbol ?? "ERC20"
        let tokenSymbol = String.adamantLocalized.wallets.erc20.sendToken(service?.tokenSymbol ?? "")
        let currencyFont = UIFont.systemFont(ofSize: 17)
        let networkFont = currencyFont.withSize(8)
        let currencyAttributes: [NSAttributedString.Key: Any] = [.font: currencyFont]
        let networkAttributes: [NSAttributedString.Key: Any] = [.font: networkFont]
      
        let defaultString = NSMutableAttributedString(
            string: tokenSymbol,
            attributes: currencyAttributes
        )
        let underlineString = NSAttributedString(
            string: " \(networkSymbol)",
            attributes: networkAttributes)
        defaultString.append(underlineString
        )
        
        return defaultString
    }
    
    override func encodeForQr(address: String) -> String? {
        return "ethereum:\(address)"
    }
}
