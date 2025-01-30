//
//  WalletCollectionViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FreakingSimpleRoundImageView
import Parchment
import CommonKit
import Combine

class WalletCollectionViewCell: PagingCell {
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencySymbolLabel: UILabel!
    @IBOutlet weak var accessoryContainerView: AccessoryContainerView!
    
    override func setPagingItem(
        _ pagingItem: PagingItem,
        selected: Bool,
        options: PagingOptions
    ) {
        guard let item = pagingItem as? WalletCollectionViewCell.Model else {
            return
        }
        update(item: item)
    }
}

private extension WalletCollectionViewCell {
    func update(item: WalletCollectionViewCell.Model) {
        currencyImageView.image = item.currencyImage
        if item.currencyNetwork.isEmpty {
            currencySymbolLabel.text = item.currencySymbol
        } else {
            let currencyFont = currencySymbolLabel.font ?? .systemFont(ofSize: 12)
            let networkFont = currencyFont.withSize(8)
            let currencyAttributes: [NSAttributedString.Key: Any] = [.font: currencyFont]
            let networkAttributes: [NSAttributedString.Key: Any] = [.font: networkFont]
          
            let defaultString = NSMutableAttributedString(string: item.currencySymbol, attributes: currencyAttributes)
            let underlineString = NSAttributedString(string: " \(item.currencyNetwork)", attributes: networkAttributes)
            defaultString.append(underlineString)
            currencySymbolLabel.attributedText = defaultString
        }
        
        if let balance = item.balance, item.isBalanceInitialized {
            if balance < 1 {
                balanceLabel.text = AdamantBalanceFormat.compact.format(balance)
            } else {
                balanceLabel.text = AdamantBalanceFormat.short.format(balance)
            }
        } else {
            balanceLabel.text = String.adamant.account.updatingBalance
        }
        
        if item.notificationBadgeCount > 0 {
            accessoryContainerView.setAccessory(AccessoryType.label(text: String(item.notificationBadgeCount)), at: .topRight)
        } else {
            accessoryContainerView.setAccessory(nil, at: .topRight)
        }
    }
}
