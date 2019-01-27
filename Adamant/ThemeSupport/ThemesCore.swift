//
//  ThemesCore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Stylist

enum AdamantTheme {
    case light
    case dark
    
    static let `default`: AdamantTheme = .light
    
    var theme: ThemeProtocol {
        switch self {
        case .light: return try! ThemeLight()
        case .dark: return try! ThemeDark()
        }
    }
    
    var title: String {
        return theme.title
    }
}

public protocol Themeable: class {
    func apply(theme: ThemeProtocol)
}

extension Themeable {
    public func observeThemeChange()
    {
        ThemeManager.default.manage(for: self)
    }
}
