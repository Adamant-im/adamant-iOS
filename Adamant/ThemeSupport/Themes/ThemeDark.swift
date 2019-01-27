//
//  ThemeDark.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit

class ThemeDark: ThemeBase {
    override var title: String {
        return NSLocalizedString("AccountTab.Row.Theme.Dark", comment: "Account tab: 'Theme' row value 'Dark'")
    }
    
    override var secondaryBackground: UIColor {
        return getColor(.third)
    }
    
    override var chatRecipientBackground: UIColor {
        return getColor(.third)
    }
    
    override var pendingChatBackground: UIColor {
        return getColor(.third)
    }
    
    override var failChatBackground: UIColor {
        return getColor(.third)
    }
    
    override var chatSenderBackground: UIColor {
        return getColor(.third)
    }
    
    override var pinpadHighlightButton: UIColor {
        return getColor(.third)
    }
    
    override var statusBar: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: Init
    
    init() throws {
        try super.init(fileName: "ThemeDark")
    }
}
