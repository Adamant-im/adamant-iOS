//
//  AMenuItem+Style.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.07.2023.
//

import SwiftUI

extension AMenuItem {
    
    public enum Style {
        
        /*
         Enum for defining the style of menu elements
         
         It can be initialised as plain (uses menu defaults), styled or uiStyled - the styled cases allow customisation of font, text colour, icon colour & background colour
         */
        
        /// The plain style case
        case plain
        
        /// The destructive style case
        case destructive

        /// The styled case
        /// - Parameters:
        ///   - font: the UIFont to use for the element
        ///   - textColor: the UIColor to use for the element text
        ///   - iconColor: the UIColor to use for the element icon
        ///   - backgroundColor: the UIColor to use for the element background
        case styled(font: UIFont? = nil, textColor: UIColor? = nil, iconColor: UIColor? = nil, backgroundColor: UIColor? = nil)
    }
}

// MARK: - Internal

public extension AMenuItem.Style {
    @MainActor
    func configure(
        titleLabel: UILabel,
        icon: UIImageView?,
        backgroundView: UIView?,
        menuAccentColor: UIColor?,
        menuFont: UIFont?
    ) {
        switch self {
        case .plain:
            let color = menuAccentColor ?? .label
            titleLabel.font = menuFont
            titleLabel.textColor = color
            icon?.tintColor = color
            
        case .destructive:
            let color = UIColor.adamant.contextMenuDestructive
            titleLabel.font = menuFont
            titleLabel.textColor = color
            icon?.tintColor = color
            
        case .styled(let font, let textColor, let iconColor, let backgroundColor):
            if let font = font {
                titleLabel.font = font
            } else if let menuFont = menuFont {
                titleLabel.font = menuFont
            }
            titleLabel.textColor = textColor ?? .label
            icon?.tintColor = iconColor ?? textColor
            if let backgroundColor = backgroundColor {
                backgroundView?.backgroundColor = backgroundColor
            }
        }
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .plain, .destructive:
            return nil
        case .styled(_, _, _, let backgroundColor):
            return backgroundColor
        }
    }
}
