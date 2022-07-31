//
//  UIColor+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension UIColor {
    public struct adamant {
        
        // MARK: Colors from Adamant Guideline
        static let first = UIColor(hex: "#474a5f")
        static let fourth = UIColor(hex: "#eeeeee")

        static let active = UIColor(hex: "#179cec")
        static let background = UIColor(hex: "#f2f6fa")
        static let alert = UIColor(hex: "#faa05a")
        
        // MARK: Global colors
        
        /// Main dark gray, ~70% gray
        static let primary = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
        
        /// Secondary color, ~50% gray
        static let secondary = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
        
        /// Chat icons color, ~40% gray
        static let chatIcons = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        
        /// Table row icons color, ~45% gray
        static let tableRowIcons = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
        
        /// Switch onTintColor
        static let switchColor = UIColor(hex: "#179cec")
        
        // MARK: Chat colors
        
        /// User chat bubble background, ~4% gray
        static let chatRecipientBackground = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
        static let pendingChatBackground = UIColor(white: 0.98, alpha: 1.0)
        static let failChatBackground = UIColor(white: 0.8, alpha: 1.0)
        
        /// Partner chat bubble background, ~8% gray
        static let chatSenderBackground = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
        
        // MARK: Pinpad
        /// Pinpad highligh button background, 12% gray
        static let pinpadHighlightButton = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
        
        // MARK: Transfers
        /// Income transfer icon background, light green
        static let transferIncomeIconBackground = UIColor(red: 0.7, green: 0.93, blue: 0.55, alpha: 1)
        
        // Outcome transfer icon background, light red
        static let transferOutcomeIconBackground = UIColor(red: 0.94, green: 0.52, blue: 0.53, alpha: 1)
    }
}
