//
//  RoundAvatarTableViewCell.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension SharedCell {
	static let RoundAvatarCell = SharedCell(cellIdentifier: "roundAvatar",
										xibName: "RoundAvatarTableViewCell",
										rowHeight: 72)
}

class RoundAvatarTableViewCell: UITableViewCell {
	
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var mainTextLabel: UILabel!
	@IBOutlet weak var detailsTextLabel: UILabel!
	
	
	// MARK: - Properties
	
	var mainText: String? {
		didSet {
			if let text = mainText, text.count > 0 {
				mainTextLabel.isHidden = false
				mainTextLabel.text = text
			} else {
				mainTextLabel.isHidden = true
			}
		}
	}
	
	var detailsText: String? {
		didSet {
			if let text = detailsText, text.count > 0 {
				detailsTextLabel.isHidden = false
				detailsTextLabel.text = text
			} else {
				detailsTextLabel.isHidden = true
			}
		}
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
