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
		
		if item.balance < 1 {
			balanceLabel.text = AdamantBalanceFormat.compact.format(item.balance)
		} else {
			balanceLabel.text = AdamantBalanceFormat.short.format(item.balance)
		}
		
		accessoryContainerView.accessoriesBackgroundColor = options.indicatorColor
		
		if item.notifications > 0 {
			accessoryContainerView.setAccessory(AccessoryType.label(text: String(item.notifications)), at: .topRight)
		} else {
			accessoryContainerView.setAccessory(nil, at: .topRight)
		}
	}
}
