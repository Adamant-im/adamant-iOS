//
//  ThemeBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Stylist

enum ThemeColors: String {
    case primary = "firstColor"
    case secondary = "secondaryColor"
    case third = "thirdColor"
    case active = "activeColor"
    case success = "successColor"
    case alert = "alertColor"
    case background = "backgroundColor"
    case alternativeBackground = "altBackgroundColor"
    case bubbleText = "bubbleTextColor"
    case bubble = "bubbleColor"
    case trailingSwipeActionBackground = "trailingSwipeActionsColor"
}

internal class ThemeBase: AdamantTheme {
    // MARK: Properties
    
    /// Using filename as id
    let id: String
    
    var title: String {
        fatalError("You must override property 'localisedTitle'")
    }
    
    var theme: Theme
    
    // MARK: - Colors
    
    var primary: UIColor {
        return getColor(.primary)
    }
    
    var secondary: UIColor {
        return getColor(.secondary)
    }
    
    var activeColor: UIColor {
        return getColor(.active)
    }
    
    var successColor: UIColor {
        return getColor(.success)
    }
    
    var alertColor: UIColor {
        return getColor(.alert)
    }
    
    var chatIcons: UIColor {
        return getColor(.primary)
    }
    
    var tableRowIcons: UIColor {
        return getColor(.primary)
    }
    
    var background: UIColor {
        return getColor(.background)
    }
    
    var secondaryBackground: UIColor {
        return getColor(.background)
    }
    
    var chatRecipientBackground: UIColor {
        return getColor(.alternativeBackground)
    }
    
    var pendingChatBackground: UIColor {
        return getColor(.background)
    }
    
    var failChatBackground: UIColor {
        return getColor(.background)
    }
    
    var chatSenderBackground: UIColor {
        return getColor(.alternativeBackground)
    }
    
    var pinpadHighlightButton: UIColor {
        return getColor(.background)
    }
    
    var transferIncomeIconBackground: UIColor {
        return getColor(.success)
    }
    
    var transferOutcomeIconBackground: UIColor {
        return getColor(.alert)
    }
    
    var statusBar: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    var bubble: UIColor {
        return getColor(.bubble)
    }
    
    var bubbleText: UIColor {
        return getColor(.bubbleText)
    }
    
    var uiAlertTextColor: UIColor {
        return UIColor(hex: "#474a5f")
    }
    
    var trailingSwipeActionsBackground: UIColor {
        return getColor(.trailingSwipeActionBackground)
    }
    
    var darkKeyboard: Bool {
        return theme.variables["darkKeyboard"] as? Bool ?? false
    }
    
    // MARK: - Init
    
    internal init(fileName: String) throws {
        self.id = fileName
        
        // Load file
        guard let path = Bundle.main.path(forResource: fileName, ofType: "yaml") else {
            throw ThemesManagerError.failedLoadingTheme
        }
        
        // Parse it
        do {
            let theme = try Theme(path: path)
            self.theme = theme
        } catch {
            throw ThemesManagerError.failedLoadingTheme
        }
    }
    
    // MARK: - Get colors
    
    func getColor(_ color: ThemeColors) -> UIColor {
        if let colorHex = theme.variables[color.rawValue] as? String {
            return UIColor(hex: colorHex)
        } else {
            return UIColor.red
        }
    }
    
    private func getColor(_ name: String) -> UIColor {
        if let colorHex = theme.variables[name] as? String {
            return UIColor(hex: colorHex)
        } else {
            return UIColor.red
        }
    }
}
