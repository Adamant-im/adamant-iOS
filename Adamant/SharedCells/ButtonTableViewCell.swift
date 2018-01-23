//
//  ButtonTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit

extension SharedCell {
	static let ButtonCell = SharedCell(cellIdentifier: "buttonCell",
									 xibName: "ButtonTableViewCell",
									 rowHeight: 44)
}

class ButtonTableViewCell: UITableViewCell {
	@IBOutlet weak var buttonLabel: UILabel!
}

extension ButtonTableViewCell: ConfigurableCell {
	func configure(with string: String) {
		buttonLabel.text = string
	}
}
