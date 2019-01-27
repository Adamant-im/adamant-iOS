//
//  ThemeProtocol.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Stylist

public protocol ThemeProtocol {
    var title: String { get }
    
    var theme: Theme { get }
    
    // MARK: Global colors
    
    /// Main color
    var primary: UIColor { get }
    
    /// Secondary color
    var secondary: UIColor { get }
    
    /// Success Color
    var successColor: UIColor { get }
    
    /// Active Color
    var activeColor: UIColor { get }
    
    /// Alert Color
    var alertColor: UIColor { get }
    
    /// Chat icons color
    var chatIcons: UIColor { get }
    
    /// Table row icons color
    var tableRowIcons: UIColor { get }
    
    var background: UIColor { get }
    var secondaryBackground: UIColor { get }
    
    // MARK: Chat colors
    
    /// User chat bubble background
    var chatRecipientBackground: UIColor { get }
    var pendingChatBackground: UIColor { get }
    var failChatBackground: UIColor { get }
    
    /// Partner chat bubble background
    var chatSenderBackground: UIColor { get }
    
    
    // MARK: Pinpad
    /// Pinpad highligh button background
    var pinpadHighlightButton: UIColor { get }
    
    
    // MARK: Transfers
    /// Income transfer icon background
    var transferIncomeIconBackground: UIColor { get }
    
    // Outcome transfer icon background
    var transferOutcomeIconBackground: UIColor { get }
    
    // Status bar
    var statusBar : UIStatusBarStyle { get }
}
