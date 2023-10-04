//
//  ChatMessageModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import Foundation

public struct ChatMessageModel: Equatable {
    public let id: String
    public let text: NSAttributedString
    public let reply: ChatReplyModel?
    public let status: ChatItemStatus
    public let isHidden: Bool
    public let firstReaction: ChatReactionModel?
    public let secondReaction: ChatReactionModel?
    
    public static let `default` = Self(
        id: .empty,
        text: .init(),
        reply: nil,
        status: .pending,
        isHidden: false,
        firstReaction: nil,
        secondReaction: nil
    )
    
    public init(
        id: String,
        text: NSAttributedString,
        reply: ChatReplyModel?,
        status: ChatItemStatus,
        isHidden: Bool,
        firstReaction: ChatReactionModel?,
        secondReaction: ChatReactionModel?
    ) {
        self.id = id
        self.text = text
        self.reply = reply
        self.status = status
        self.isHidden = isHidden
        self.firstReaction = firstReaction
        self.secondReaction = secondReaction
    }
}
