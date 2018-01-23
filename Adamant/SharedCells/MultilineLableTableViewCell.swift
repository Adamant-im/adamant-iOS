//
//  MultilineLableTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit

class MultilineLableTableViewCell: UITableViewCell {
	@IBOutlet weak var multilineLabel: UILabel!
	@IBOutlet weak var detailsMultilineLabel: UILabel!
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		contentView.layoutIfNeeded()
		
		multilineLabel.preferredMaxLayoutWidth = multilineLabel.bounds.size.width
	}
}


// MARK: - ConfigurableCell
extension MultilineLableTableViewCell: ConfigurableCell {
	func configure(with string: String) {
		
		multilineLabel.text = string
	}
}
