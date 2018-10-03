//
//  DoubleDetailsTableViewCell
//  Adamant
//
//  Created by Anokhov Pavel on 30.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

public final class DoubleDetailsTableViewCell: UITableViewCell {
	
	// MARK: Constants
	static let compactHeight: CGFloat = 50.0
	static let fullHeight: CGFloat = 70.0
	
	// MARK: IBOutlets
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var detailsLabel: UILabel!
	@IBOutlet var secondDetailsLabel: UILabel!
	
	// MARK: Properties
	var secondValue: String? {
		get {
			return secondDetailsLabel.text
		}
		set {
			secondDetailsLabel.text = newValue
			if newValue == nil {
				secondDetailsLabel.isHidden = true
			}
		}
	}
}
