//
//  ERC20WalletViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit

extension String.adamant.wallets {
    enum erc20 {
        static func tokenWallet(_ token: String) -> String {
            return String(format: .localized("AccountTab.Wallets.erc20_wallet", comment: "Account tab: Ethereum wallet"), token)
        }
        
        static func secretTokenWallet(_ token: String) -> String {
            return String(format: .localized("SecretWallets.erc20_wallet.Secret", comment: "Account tab: Ethereum wallet"), token)
        }
        
        static func sendToken(_ token: String) -> String {
            return String(format: .localized("AccountTab.Row.SendToken", comment: "Account tab: 'Send ERC20 tokens' button"), token)
        }
    }
}

final class ERC20WalletViewController: WalletViewControllerBase {
    override func sendRowLocalizedLabel() -> NSAttributedString {
        let networkSymbol = ERC20WalletService.tokenNetworkSymbol
        let tokenSymbol = String.adamant.wallets.erc20.sendToken(service?.core.tokenSymbol ?? "")
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
            attributes: networkAttributes
        )
        
        defaultString.append(underlineString)
        
        return defaultString
    }
    
    override func encodeForQr(address: String) -> String? {
        return "ethereum:\(address)"
    }
    
    override func setTitle() {
        walletTitleLabel.text = makeTitle()
    }
    
    override func makeTitle() -> String {
        let index = secretWalletsViewModel.state.currentActiveIndex
        if index <= 0 {
            return String.adamant.wallets.erc20.tokenWallet(service?.core.tokenName ?? "")
        } else {
            return String.adamant.wallets.erc20.secretTokenWallet(service?.core.tokenName ?? "") + " \(index)"
        }
    }
}
