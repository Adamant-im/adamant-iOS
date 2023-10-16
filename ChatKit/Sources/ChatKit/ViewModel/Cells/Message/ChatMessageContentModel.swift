//
//  ChatMessageContentModel.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import Foundation

public struct ChatMessageContentModel: Equatable {
    public let text: NSAttributedString
    public let reply: ChatReplyModel?
    public let status: ChatItemStatus
    
    public static let `default` = Self(text: .init(), reply: nil, status: .pending)
    
    public init(text: NSAttributedString, reply: ChatReplyModel?, status: ChatItemStatus) {
        self.text = text
        self.reply = reply
        self.status = status
    }
}
