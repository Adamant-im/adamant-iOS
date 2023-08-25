//
//  AMenuItem.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.07.2023.
//

import SwiftUI

public enum AMenuItem {
    
    /// The case for an action menu item
    /// - Parameters:
    ///   - name: the menu item name (as it appears in the menu)
    ///   - imageName: the name of an image for the menu item icon (nil for no image)
    ///   - systemImageName: the name of a system image for the menu item icon (nil for no image)
    ///   - style: the style for the menu item
    ///   - action: the action invoked when the menu item is selected
    case action(
        title: String,
        imageName: String? = nil,
        systemImageName: String?,
        style: Style = .plain,
        action: (() -> Void)
    )
    
    /// Creates an action menu item
    /// - Parameters:
    ///   - name: the menu item name (as it appears in the menu)
    ///   - imageName: the name of an image for the menu item icon (nil for no image)
    ///   - style: the style for the menu item
    ///   - action: the action invoked when the menu item is selected
    /// - Returns: the .action enum case, with the provided parameters
    public static func action(
        title: String,
        imageName: String? = nil,
        style: Style = .plain,
        action: @escaping (() -> Void)
    ) -> AMenuItem {
        return .action(
            title: title,
            imageName: imageName,
            systemImageName: nil,
            style: style,
            action: action
        )
    }
    
    /// Creates an action menu item
    /// - Parameters:
    ///   - name: the menu item name (as it appears in the menu)
    ///   - systemImageName: the name of a system image for the menu item icon (nil for no image)
    ///   - style: the style for the menu item
    ///   - action: the action invoked when the menu item is selected
    /// - Returns: the .action enum case, with the provided parameters
    public static func action(
        title: String,
        systemImageName: String,
        style: Style = .plain,
        action: @escaping (() -> Void)
    ) -> AMenuItem {
        return .action(
            title: title,
            imageName: nil,
            systemImageName: systemImageName,
            style: style,
            action: action
        )
    }
}

// MARK: - Internal

public extension AMenuItem {
    var name: String {
        switch self {
        case .action(let name, _, _, _, _):
            return name
        }
    }
    
    var iconImage: UIImage? {
        switch self {
        case .action(_, let imageName, let systemImageName, _, _):
            if let imageName = imageName {
                return UIImage(named: imageName)
            } else if let systemImageName = systemImageName {
                return UIImage(systemName: systemImageName)
            }
            return nil
        }
    }
    
    var style: Style {
        switch self {
        case .action(_, _, _, let style, _):
            return style
        }
    }
    
    var action: () -> Void {
        switch self {
        case .action(_, _, _, _, let action):
            return action
        }
    }
}
