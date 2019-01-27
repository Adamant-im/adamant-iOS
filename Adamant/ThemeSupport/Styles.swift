//
//  Styles.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit

enum AdamantThemeStyleProperty: String {
    case separatorColor = "separatorColor"
    case placeholderColor = "placeholderColor"
    case clearButtonTintColor = "clearButtonTintColor"
    case showDarkKeyboard = "showDarkKeyboard"
    case avatarTintColor = "avatarTintColor"
    case badgeColor = "badgeColor"
    case largeTextColor = "largeTextColor"
    case butttonsColor = "butttonsColor"
    case buttonsHighlightedColor = "buttonsHighlightedColor"
    case placeholderActiveColor = "placeholderActiveColor"
    case placeholderNormalColor = "placeholderNormalColor"
    case indicatorColor = "indicatorColor"
    case selectedTextColor = "selectedTextColor"
    case barTintColor = "barTintColor"
    case isDarkMode = "isDarkMode"
    case textColor = "textColor"
    case backgroundColor = "backgroundColor"
    case normalBackgroundColor = "normalBackgroundColor"
    case highlightedBackgroundColor = "highlightedBackgroundColor"
    case selectedBackgroundColor = "selectedBackgroundColor"
    case menuBackgroundColor = "menuBackgroundColor"
    
    static func joined(styles: [AdamantThemeStyleProperty]) -> String {
        return styles.compactMap { $0.rawValue }.joined(separator: ",")
    }
}

enum AdamantThemeStyle: String {
    // MARK: Base
    case primaryText = "primaryText"
    case secondaryText = "secondaryText"
    
    case baseNavigationBar = "baseNavigationBar"
    case primaryTint = "primaryTint"
    case baseBarTint = "baseBarTint"
    case input = "input"
    case tabItem = "tabItem"
    case biometricButton = "biometricButton"
    case secondaryBorder = "secondaryBorder"
    
    case primaryBackground = "primaryBackground"
    case secondaryBackground = "secondaryBackground"
    case activeBackground = "activeBg"
    
    case chatCell = "chatCell"
    
    // MARK: viewControllers
    case paging = "paging"
    case pinpad = "pinpad"
    
    // MARK: tableViews
    case baseTable = "baseTable"
    case baseTableViewCell = "baseTableCell"
    case baseTabieViewCellWithBackground
    
    static func joined(_ styles: [AdamantThemeStyle]) -> String {
        return styles.map { $0.rawValue }.joined(separator: ",")
    }
    
    static var commonTableViewCell = AdamantThemeStyle.joined([.baseTableViewCell, .secondaryBackground])
    static var primaryTintAndBackground = AdamantThemeStyle.joined([.primaryBackground, .primaryTint])
}

// MARK: - Stylist
extension UIViewController {
    func setStyle(_ adamantStyle: AdamantThemeStyle) {
        style = adamantStyle.rawValue
    }
    
    func setStyle(_ styles: [AdamantThemeStyle]) {
        style = AdamantThemeStyle.joined(styles)
    }
}

extension UIView {
    func setStyle(_ adamantStyle: AdamantThemeStyle) {
        style = adamantStyle.rawValue
    }
    
    func setStyles(_ styles: [AdamantThemeStyle]) {
        style = AdamantThemeStyle.joined(styles)
    }
}

extension UIBarItem {
    func setStyle(_ adamantStyle: AdamantThemeStyle) {
        style = adamantStyle.rawValue
    }
    
    func setStyle(_ styles: [AdamantThemeStyle]) {
        style = AdamantThemeStyle.joined(styles)
    }
}
