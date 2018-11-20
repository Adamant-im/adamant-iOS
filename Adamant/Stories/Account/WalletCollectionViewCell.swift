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

class WalletCollectionViewCell: PagingCell {
	@IBOutlet weak var currencyImageView: UIImageView!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var currencySymbolLabel: UILabel!
	@IBOutlet weak var accessoryContainerView: AccessoryContainerView!
	
	override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
		guard let item = pagingItem as? WalletPagingItem else {
			return
		}
		
		currencyImageView.image = item.currencyImage
		currencySymbolLabel.text = item.currencySymbol
		
        if let balance = item.balance {
            if balance < 1 {
                balanceLabel.text = AdamantBalanceFormat.compact.format(balance)
            } else {
                balanceLabel.text = AdamantBalanceFormat.short.format(balance)
            }
        } else {
            balanceLabel.text = String.adamantLocalized.account.updatingBalance
        }
		
		accessoryContainerView.accessoriesBackgroundColor = options.indicatorColor
		
		if item.notifications > 0 {
			accessoryContainerView.setAccessory(AccessoryType.label(text: String(item.notifications)), at: .topRight)
		} else {
			accessoryContainerView.setAccessory(nil, at: .topRight)
		}
	}
}
