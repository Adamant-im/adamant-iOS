//
//  GlobalConstants.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension UIColor {
	// MARK: Global colors
	
	/// UIColor(named: "Gray_main")
	static let adamantPrimary = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
	
	/// UIColor(named: "Gray_secondary")
	static let adamantSecondary = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
	
	/// UIColor(named: "Icons")
	static let adamantChatIcons = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
	
	
	// MARK: Chat colors
	
	/// UIColor(named:  "Chat_recipient")
	static let adamantChatRecipientBackground = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
	
	/// UIColor(named: "Chat_sender")!
	static let adamantChatSenderBackground = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
}

extension UIFont {
	static func adamantPrimary(size: CGFloat) -> UIFont {
		return UIFont(name: "Exo 2", size: size)!
	}
}

