//
//  ChatContextMenuArguments.swift
//  
//
//  Created by Stanislav Jelezoglo on 25.08.2023.
//

import UIKit

public struct ChatContextMenuArguments: @unchecked Sendable {
    public let copyView: UIView
    public let size: CGSize
    public let location: CGPoint
    public let tapLocation: CGPoint
    public let messageId: String
    public let menu: AMenuSection
    public let selectedEmoji: String?
    public let getPositionOnScreen: () -> CGPoint
    
    public init(
        copyView: UIView,
        size: CGSize,
        location: CGPoint,
        tapLocation: CGPoint,
        messageId: String,
        menu: AMenuSection,
        selectedEmoji: String?,
        getPositionOnScreen: @escaping () -> CGPoint
    ) {
        self.copyView = copyView
        self.size = size
        self.location = location
        self.tapLocation = tapLocation
        self.messageId = messageId
        self.menu = menu
        self.selectedEmoji = selectedEmoji
        self.getPositionOnScreen = getPositionOnScreen
    }
    
}
