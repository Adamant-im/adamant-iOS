//
//  ChatTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
	// MARK: - IBOutlets
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var lastMessageLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	var avatarImage: UIImage? {
		get {
			return avatarImageView.image
		}
		set {
			if let avatarImage = avatarImage {
				avatarImageView.image = avatarImage
			} else {
				avatarImageView.image = #imageLiteral(resourceName: "Chat")
			}
		}
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
