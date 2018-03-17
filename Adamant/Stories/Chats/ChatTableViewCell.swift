//
//  ChatTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FreakingSimpleRoundImageView

class ChatTableViewCell: UITableViewCell {
	// MARK: - IBOutlets
	@IBOutlet weak var avatarImageView: RoundImageView!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var lastMessageLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var badgeView: UIView!
	
	override func awakeFromNib() {
		badgeView.layer.cornerRadius = badgeView.bounds.height / 2
	}
	
	var avatarImage: UIImage? {
		get {
			return avatarImageView.image
		}
		set {
			if let avatarImage = newValue {
				avatarImageView.image = avatarImage
			} else {
				avatarImageView.image = #imageLiteral(resourceName: "Chat")
			}
		}
	}
	
	var borderWidth: CGFloat {
		get {
			return avatarImageView.borderWidth
		}
		set {
			avatarImageView.borderWidth = newValue
		}
	}
	
	var borderColor: UIColor? {
		get {
			return avatarImageView.borderColor
		}
		set {
			avatarImageView.borderColor = newValue
		}
	}
	
	var hasUnreadMessages: Bool = false {
		didSet {
			badgeView.isHidden = !hasUnreadMessages
		}
	}
	
	var badgeColor: UIColor? {
		get {
			return badgeView.backgroundColor
		}
		set {
			badgeView.backgroundColor = newValue
		}
	}
}
