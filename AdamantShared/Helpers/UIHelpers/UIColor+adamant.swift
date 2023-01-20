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
        
        static func returnColorByTheme(colorWhiteTheme: UIColor, colorDarkTheme: UIColor) -> UIColor {
            UIColor { traits -> UIColor in
                return traits.userInterfaceStyle == .dark ? colorDarkTheme : colorWhiteTheme
            }
        }
        
        // MARK: Colors from Adamant Guideline
        static let first = UIColor(hex: "#474a5f")
        static let fourth = UIColor(hex: "#eeeeee")

        static let active = UIColor(red: 0.0901961, green: 0.611765, blue: 0.92549, alpha: 1)
        static let alert = UIColor(hex: "#faa05a")
        static let good = UIColor(hex: "#32d296")
        static let danger = UIColor(hex: "#f0506e")
        static let inactive = UIColor(hex: "#6d6f72")
        
        static var background: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#f2f6fa")
            let colorDarkTheme   = UIColor(hex: "#1c1c1c")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Global colors
        
        /// Default background color
        static var backgroundColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Second default background color
        static var secondBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#f2f1f6")
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Welcome background color
        static var welcomeBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(patternImage: #imageLiteral(resourceName: "stripeBg"))
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        /// Default text color
        static var textColor: UIColor {
            let colorWhiteTheme  = UIColor.black
            let colorDarkTheme   = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Default cell alert text color
        static var cellAlertTextColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Default cell color
        static var cellColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#1c1c1d")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Main dark gray, ~70% gray
        static var primary: UIColor {
            let colorWhiteTheme = UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
            let colorDarkTheme = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Secondary color, ~50% gray
        static var secondary: UIColor {
            let colorWhiteTheme = UIColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Chat icons color, ~40% gray
        static var chatIcons: UIColor {
            let colorWhiteTheme = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.278, green: 0.278, blue: 0.278, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Table row icons color, ~45% gray
        static var tableRowIcons: UIColor {
            let colorWhiteTheme = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Switch onTintColor
        static var switchColor: UIColor {
            let colorWhiteTheme = UIColor(hex: "#179cec")
            let colorDarkTheme  = UIColor(hex: "#05456b")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Chat colors
        
        /// User chat bubble background, ~4% gray
        static var chatRecipientBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
            let colorDarkTheme   = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        static var pendingChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.98, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        static var failChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.8, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        static var chatSenderBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)
            let colorDarkTheme   = UIColor(red: 0.21, green: 0.21, blue: 0.21, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        static var chatInputBarBackground: UIColor {
            let colorWhiteTheme  = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
            let colorDarkTheme   = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// InputBar field background, ~8% gray
        static var chatInputFieldBarBackground: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = UIColor(hex: "#212121")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Border colors for readOnly mode
        static var disableBorderColor: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#B0B0B0")
            let colorDarkTheme   = UIColor(hex: "#878787")
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        static let chatInputBarBorderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
        
        /// Color of input bar placeholder
        static let chatPlaceholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
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
