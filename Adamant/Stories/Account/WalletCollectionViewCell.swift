//
//  WalletCollectionViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class WalletCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var currencyImageView: UIImageView!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var currencySymbolLabel: UILabel!
	@IBOutlet weak var markerView: UIView!
	@IBOutlet weak var markerWidthConstraint: NSLayoutConstraint!
	
	var activeMarkerMultiplier: CGFloat = 0.68
	var markerAnimationDuration: TimeInterval = 0.15
	
	override var tintColor: UIColor! {
		didSet {
			markerView.backgroundColor = tintColor
		}
	}
	
	override var isSelected: Bool {
		didSet {
			setSelected(isSelected, animated: true)
		}
	}
	
	func setSelected(_ selected: Bool, animated: Bool) {
		let width = selected ? frame.width * activeMarkerMultiplier : 0.0
		if animated {
			UIView.animate(withDuration: markerAnimationDuration) {
				self.markerWidthConstraint.constant = width
				self.layoutIfNeeded()
			}
		} else {
			markerWidthConstraint.constant = width
		}
	}
}
