//
//  ChatContextMenuArguments.swift
//  
//
//  Created by Stanislav Jelezoglo on 25.08.2023.
//

import UIKit

public struct ChatContextMenuArguments {
    public let copyView: UIView
    public let size: CGSize
    public let location: CGPoint
    public let tapLocation: CGPoint
    public let messageId: String
    public let menu: AMenuSection
    public let selectedEmoji: String?
    
    public init(
        copyView: UIView,
        size: CGSize,
        location: CGPoint,
        tapLocation: CGPoint,
        messageId: String,
        menu: AMenuSection,
        selectedEmoji: String?
    ) {
        self.copyView = copyView
        self.size = size
        self.location = location
        self.tapLocation = tapLocation
        self.messageId = messageId
        self.menu = menu
        self.selectedEmoji = selectedEmoji
    }
    
}
