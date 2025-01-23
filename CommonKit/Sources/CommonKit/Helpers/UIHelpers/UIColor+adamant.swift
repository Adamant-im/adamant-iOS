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
        public static let active = #colorLiteral(red: 0.09019607843, green: 0.6117647059, blue: 0.9215686275, alpha: 1) //#179CEB
        public static let attention = #colorLiteral(red: 0.9902971387, green: 0.6896653175, blue: 0.4256819189, alpha: 1) //#faa05a
        public static let success = #colorLiteral(red: 0.2102436721, green: 0.8444728255, blue: 0.6537195444, alpha: 1) //#32d296
        public static let warning = #colorLiteral(red: 0.9622407556, green: 0.4130832553, blue: 0.5054324269, alpha: 1) //#f0506e
        public static let inactive = #colorLiteral(red: 0.5025414228, green: 0.5106091499, blue: 0.5218499899, alpha: 1) //#6d6f72
        
        public static var background: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.9590962529, green: 0.9721178412, blue: 0.9845080972, alpha: 1) //f2f6fa
            let colorDarkTheme   = #colorLiteral(red: 0.1462407112, green: 0.1462407112, blue: 0.1462407112, alpha: 1) //1c1c1c
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Global colors
        
        /// Income Arrow View Background Color
        public static var incomeArrowBackgroundColor: UIColor {
            return #colorLiteral(red: 0.2381577492, green: 0.7938874364, blue: 0.2725245357, alpha: 1) //36C436
        }
        
        /// Outcome Arrow View Background Color
        public static var outcomeArrowBackgroundColor: UIColor {
            return #colorLiteral(red: 0.9752754569, green: 0.3635693789, blue: 0.3339065611, alpha: 1) //F44444
        }
        
        /// Default background color
        public static var backgroundColor: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = #colorLiteral(red: 0.1726317406, green: 0.1726317406, blue: 0.1726317406, alpha: 1) //212121
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Second default background color
        public static var secondBackgroundColor: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.9594989419, green: 0.956831634, blue: 0.9719926715, alpha: 1) //f2f1f6
            let colorDarkTheme   = #colorLiteral(red: 0.1725490196, green: 0.1725490196, blue: 0.1725490196, alpha: 1) //2C2C2C
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Welcome background color
        public static var welcomeBackgroundColor: UIColor {
            let colorWhiteTheme  = UIColor(patternImage: .asset(named: "stripeBg") ?? .init())
            let colorDarkTheme   = #colorLiteral(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1) //212121
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
            let colorDarkTheme   = #colorLiteral(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1) //212121
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Default cell color
        public static var cellColor: UIColor {
            guard !isMacOS else { return .secondarySystemGroupedBackground }
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1137254902, alpha: 1) //1c1c1d
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Code block background color
        public static var codeBlock: UIColor {
            let colorWhiteTheme = UIColor(hex: "#4a4a4a").withAlphaComponent(0.1)
            let colorDarkTheme = #colorLiteral(red: 0.1647058824, green: 0.1647058824, blue: 0.168627451, alpha: 1) //2a2a2b
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Code block text color
        public static var codeBlockText: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.3215686275, green: 0.3215686275, blue: 0.3215686275, alpha: 1) //525252
            let colorDarkTheme = UIColor.white.withAlphaComponent(0.8)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Reactions background color
        public static var reactionsBackground: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9490196078, alpha: 1) //F2F2F2
            let colorDarkTheme = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1) //434343
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// More reactions background button color
        public static var moreReactionsBackground: UIColor {
            let colorWhiteTheme = UIColor.white
            let colorDarkTheme = #colorLiteral(red: 0.2196078431, green: 0.2196078431, blue: 0.2196078431, alpha: 1) //383838
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Picked reaction background color
        public static var pickedReactionBackground: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#EBECED").withAlphaComponent(0.85)
            let colorDarkTheme   = #colorLiteral(red: 0.3294117647, green: 0.3294117647, blue: 0.3294117647, alpha: 1) //545454
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Main dark gray, ~70% gray
        public static var primary: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.2901960784, green: 0.2901960784, blue: 0.2901960784, alpha: 1) //4A4A4A
            let colorDarkTheme = UIColor.white
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Secondary color, ~50% gray
        public static var secondary: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.4784313725, green: 0.4784313725, blue: 0.4784313725, alpha: 1) //7A7A7A
            let colorDarkTheme  = #colorLiteral(red: 0.8784313725, green: 0.8784313725, blue: 0.8784313725, alpha: 1) //E0E0E0
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Chat icons color, ~40% gray
        public static var chatIcons: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) //9E9E9E
            let colorDarkTheme  = #colorLiteral(red: 0.2784313725, green: 0.2784313725, blue: 0.2784313725, alpha: 1) //474747
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Table row icons color, ~45% gray
        public static var tableRowIcons: UIColor {
            let colorWhiteTheme = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            let colorDarkTheme  = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Chat list, swipe color
        public static var swipeMoreColor: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.8784313725, green: 0.8784313725, blue: 0.8784313725, alpha: 1) //E0E0E0
            let colorDarkTheme = #colorLiteral(red: 0.3294117647, green: 0.3294117647, blue: 0.3294117647, alpha: 1) //545454
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var swipeBlockColor: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.9254901961, green: 0.9254901961, blue: 0.9254901961, alpha: 1) //ECECEC
            let colorDarkTheme = #colorLiteral(red: 0.2705882353, green: 0.2705882353, blue: 0.2705882353, alpha: 1) //474747
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Switch onTintColor
        public static var switchColor: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.09019607843, green: 0.6117647059, blue: 0.9254901961, alpha: 1) //179cec
            let colorDarkTheme  = #colorLiteral(red: 0.01960784314, green: 0.2705882353, blue: 0.4196078431, alpha: 1) //05456b
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Secondary color, ~50% gray
        public static var errorOkButton: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.4784313725, green: 0.4784313725, blue: 0.4784313725, alpha: 1) //7A7A7A
            let colorDarkTheme  = #colorLiteral(red: 0.3098039216, green: 0.3098039216, blue: 0.3098039216, alpha: 1) //4F4F4F
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        // MARK: Chat colors
        
        /// User chat bubble background, ~4% gray
        public static var chatRecipientBackground: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.9647058824, green: 0.9725490196, blue: 0.9843137255, alpha: 1) //F6F8FB
            let colorDarkTheme   = #colorLiteral(red: 0.2705882353, green: 0.2705882353, blue: 0.2705882353, alpha: 1) //454545
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var pendingChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.98, alpha: 1.0)
            let colorDarkTheme   = #colorLiteral(red: 0.4196078431, green: 0.4196078431, blue: 0.4196078431, alpha: 1) //6B6B6B
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var failChatBackground: UIColor {
            let colorWhiteTheme  = UIColor(white: 0.8, alpha: 1.0)
            let colorDarkTheme   = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1) //757575
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        public static var chatSenderBackground: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.9254901961, green: 0.9254901961, blue: 0.9254901961, alpha: 1) //ECECEC
            let colorDarkTheme   = #colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1) //363636
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Partner chat bubble background, ~8% gray
        public static var chatInputBarBackground: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1) //F7F7F7
            let colorDarkTheme   = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1) //333333
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// InputBar field background, ~8% gray
        public static var chatInputFieldBarBackground: UIColor {
            let colorWhiteTheme  = UIColor.white
            let colorDarkTheme   = #colorLiteral(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1) //212121
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        /// Border colors for readOnly mode
        public static var disableBorderColor: UIColor {
            let colorWhiteTheme  = #colorLiteral(red: 0.6901960784, green: 0.6901960784, blue: 0.6901960784, alpha: 1) //B0B0B0
            let colorDarkTheme   = #colorLiteral(red: 0.5294117647, green: 0.5294117647, blue: 0.5294117647, alpha: 1) //878787
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static let chatInputBarBorderColor = #colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1) //C8C8C8
        
        /// Color of input bar placeholder
        public static let chatPlaceholderTextColor = #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) //999999
        
        // MARK: Context Menu
        
        public static var contextMenuLineColor: UIColor {
            let colorWhiteTheme  = UIColor(hex: "#BFBFBF").withAlphaComponent(0.8)
            let colorDarkTheme   = UIColor(hex: "#808080").withAlphaComponent(0.8)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuSelectColor: UIColor {
            let colorWhiteTheme  = UIColor.black.withAlphaComponent(0.10)
            let colorDarkTheme   = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1) //#373737
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuDefaultBackgroundColor: UIColor {
            let colorWhiteTheme = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9490196078, alpha: 1) //#F2F2F2
            let colorDarkTheme   = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1) //#434343
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
  
        public static var contextMenuOverlayMacColor: UIColor {
            let colorWhiteTheme  = UIColor.black.withAlphaComponent(0.3)
            let colorDarkTheme   = UIColor.white.withAlphaComponent(0.3)
            return returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
        }
        
        public static var contextMenuDestructive: UIColor {
            #colorLiteral(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1) //#FF3823
        }
        
        // MARK: Pinpad
        /// Pinpad highligh button background, 12% gray
        public static let pinpadHighlightButton = #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1) //#E1E1E1
        
        // MARK: Transfers
        /// Income transfer icon background, light green
        public static let transferIncomeIconBackground = #colorLiteral(red: 0.7019607843, green: 0.9294117647, blue: 0.5490196078, alpha: 1) //#B3ED8C
        
        // Outcome transfer icon background, light red
        public static let transferOutcomeIconBackground = #colorLiteral(red: 0.9411764706, green: 0.5215686275, blue: 0.5294117647, alpha: 1) //#F08587
    }
}
