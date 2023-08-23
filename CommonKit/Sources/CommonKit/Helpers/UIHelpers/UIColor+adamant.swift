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
        
        public static func returnColorByTheme(
            colorWhiteTheme: UIColor,
            colorDarkTheme: UIColor
        ) -> UIColor {
            UIColor { traits -> UIColor in
                return traits.userInterfaceStyle == .dark ? colorDarkTheme : colorWhiteTheme
            }
        }
        
        // MARK: Colors from Adamant Guideline
        public static let first = UIColor(hex: "#474a5f")
        public static let fourth = UIColor(hex: "#eeeeee")

        public static let active = UIColor(red: 0.0901961, green: 0.611765, blue: 0.92549, alpha: 1)
        public static let alert = UIColor(hex: "#faa05a")
        public static let good = UIColor(hex: "#32d296")
        public static let danger = UIColor(hex: "#f0506e")
        public static let inactive = UIColor(hex: "#6d6f72")
        
        public static var background: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#f2f6fa")
            let colorDarkTheme   = UIColor(hex: "#1c1c1c")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Global colors
        
        /// Income Arrow View Background Color
        public static var incomeArrowBackgroundColor: UIColor {
            return UIColor(hex: "36C436")
        }
        
        /// Outcome Arrow View Background Color
        public static var outcomeArrowBackgroundColor: UIColor {
            return UIColor(hex: "F44444")
        }
        
        /// Default background color
        public static var backgroundColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Second default background color
        public static var secondBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#f2f1f6")
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Welcome background color
        public static var welcomeBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(patternImage: .asset(named: "stripeBg") ?? .init())
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        /// Default text color
        public static var textColor: UIColor {
            let colorWhiteTheme  = UIColor.black
            let colorDarkTheme   = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Default cell alert text color
        public static var cellAlertTextColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Default cell color
        public static var cellColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#1c1c1d")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Code block background color
        public static var codeBlock: UIColor {
            let colorWhiteTheme = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 0.1)
            let colorDarkTheme = UIColor(hex: "#2a2a2b")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Code block text color
        public static var codeBlockText: UIColor {
            let colorWhiteTheme = UIColor(red: 0.32, green: 0.32, blue: 0.32, alpha: 1)
            let colorDarkTheme = UIColor.white.withAlphaComponent(0.8)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Reactions background color
        public static var reactionsBackground: UIColor {
            let colorWhiteTheme = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 0.1)
            let colorDarkTheme = UIColor(red: 0.264, green: 0.264, blue: 0.264, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// More reactions background button color
        public static var moreReactionsBackground: UIColor {
            let colorWhiteTheme = UIColor.white
            let colorDarkTheme = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Picked reaction background color
        public static var pickedReactionBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.278, green: 0.278, blue: 0.278, alpha: 1.0)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Main dark gray, ~70% gray
        public static var primary: UIColor {
            let colorWhiteTheme = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
            let colorDarkTheme = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Secondary color, ~50% gray
        public static var secondary: UIColor {
            let colorWhiteTheme = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Chat icons color, ~40% gray
        public static var chatIcons: UIColor {
            let colorWhiteTheme = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.278, green: 0.278, blue: 0.278, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Table row icons color, ~45% gray
        public static var tableRowIcons: UIColor {
            let colorWhiteTheme = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Switch onTintColor
        public static var switchColor: UIColor {
            let colorWhiteTheme = UIColor(hex: "#179cec")
            let colorDarkTheme  = UIColor(hex: "#05456b")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Secondary color, ~50% gray
        public static var errorOkButton: UIColor {
            let colorWhiteTheme = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Chat colors
        
        /// User chat bubble background, ~4% gray
        public static var chatRecipientBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
            let colorDarkTheme   = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var pendingChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.98, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var failChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.8, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        public static var chatSenderBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
            let colorDarkTheme   = UIColor(red: 0.21, green: 0.21, blue: 0.21, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        public static var chatInputBarBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// InputBar field background, ~8% gray
        public static var chatInputFieldBarBackground: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Border colors for readOnly mode
        public static var disableBorderColor: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#B0B0B0")
            let colorDarkTheme   = UIColor(hex: "#878787")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static let chatInputBarBorderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
        
        /// Color of input bar placeholder
        public static let chatPlaceholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
        // MARK: Context Menu
        
        public static var contextMenuLineColor: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.8)
            let colorDarkTheme   = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.8)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuSelectColor: UIColor {
            let colorWhiteTheme  = UIColor.black.withAlphaComponent(0.10)
            let colorDarkTheme   = UIColor(red: 0.214, green: 0.214, blue: 0.214, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuDefaultBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            let colorDarkTheme   = UIColor(red: 0.264, green: 0.264, blue: 0.264, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuTextColor: UIColor {
            let colorWhiteTheme  = UIColor.black
            let colorDarkTheme   = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuOverlayMacColor: UIColor {
            let colorWhiteTheme  = UIColor.black.withAlphaComponent(0.3)
            let colorDarkTheme   = UIColor.white.withAlphaComponent(0.3)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuDestructive: UIColor {
            UIColor(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1)
        }
        
        // MARK: Pinpad
        /// Pinpad highligh button background, 12% gray
        public static let pinpadHighlightButton = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
        
        // MARK: Transfers
        /// Income transfer icon background, light green
        public static let transferIncomeIconBackground = UIColor(red: 0.7, green: 0.93, blue: 0.55, alpha: 1)
        
        // Outcome transfer icon background, light red
        public static let transferOutcomeIconBackground = UIColor(red: 0.94, green: 0.52, blue: 0.53, alpha: 1)
    }
}
