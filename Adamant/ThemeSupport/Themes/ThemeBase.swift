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
}

class ThemeBase: ThemeProtocol {
    // MARK: Properties
    var title: String {
        fatalError("You must override theme title")
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
    
    // MARK: - Init
    
    internal init(fileName: String) throws {
        // Check cached themes
        if let theme = ThemeManager.themes[fileName] {
            self.theme = theme
            return
        }
        
        // Load file
        guard let path = Bundle.main.path(forResource: fileName, ofType: "yaml") else {
            throw ThemeManagerError.failedLoadingTheme
        }
        
        // Parse it
        do {
            let theme = try Theme(path: path)
            self.theme = theme
            ThemeManager.themes[fileName] = theme
        } catch {
            throw ThemeManagerError.failedLoadingTheme
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
