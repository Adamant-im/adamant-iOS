//
//  UIColor+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.07.2018.
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
	
	/// Table row icons color, ~45% gray
	static let adamantTableRowIcons = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
	
	
	// MARK: Chat colors
	
	/// User chat bubble background, ~4% gray
	static let adamantChatRecipientBackground = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
	static let adamantPendingChatBackground = UIColor(white: 0.98, alpha: 1.0)
	static let adamantFailChatBackground = UIColor(white: 0.8, alpha: 1.0)
	
	/// Partner chat bubble background, ~8% gray
	static let adamantChatSenderBackground = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
	
	
	// MARK: Pinpad
	/// Pinpad highligh button background, 12% gray
	static let adamantPinpadHighlightButton = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
	
	
	// MARK: Transfers
	/// Income transfer icon background, light green
	static let adamantTransferIncomeIconBackground = UIColor(red: 0.7, green: 0.93, blue: 0.55, alpha: 1)
	
	// Outcome transfer icon background, light red
	static let adamantTransferOutcomeIconBackground = UIColor(red: 0.94, green: 0.52, blue: 0.53, alpha: 1)
}
