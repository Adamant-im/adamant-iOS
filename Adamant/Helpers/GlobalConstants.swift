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
	
	/// Main dark gray, ~70% gray
	static let adamantPrimary = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
	
	/// Secondary color, ~50% gray
	static let adamantSecondary = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
	
	/// Chat icons color, ~40% gray
	static let adamantChatIcons = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
	
	
	// MARK: Chat colors
	
	/// User chat bubble background, ~4% gray
	static let adamantChatRecipientBackground = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
    static let adamantPendingChatBackground = UIColor(white: 0.94, alpha: 1.0)
    static let adamantFailChatBackground = UIColor(white: 0.8, alpha: 1.0)
	
	/// Partner chat bubble background, ~8% gray
	static let adamantChatSenderBackground = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
	
	
	// MARK: Pinpad
	/// Pinpad highligh button background, 12% gray
	static let adamantPinpadHighlightButton = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
}

extension UIFont {
	static func adamantPrimary(size: CGFloat) -> UIFont {
		return UIFont(name: "Exo 2", size: size)!
	}
	
	static func adamantPrimaryLight(size: CGFloat) -> UIFont {
		return UIFont(name: "Exo 2 Light", size: size)!
	}
	
	static func adamantPrimaryThin(size: CGFloat) -> UIFont {
		return UIFont(name: "Exo 2 Thin", size: size)!
	}
	
	static var adamantChatDefault = UIFont.systemFont(ofSize: 17)
}

extension Date {
	static let adamantNullDate = Date(timeIntervalSince1970: 0)
}
