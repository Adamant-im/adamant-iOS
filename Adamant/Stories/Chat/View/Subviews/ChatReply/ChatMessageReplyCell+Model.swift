//
//  ChatMessageReplyCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatMessageReplyCell {
    struct Model: Equatable, MessageModel {
        let id: String
        let replyId: String
        let message: NSAttributedString
        let messageReply: NSAttributedString
        let backgroundColor: ChatMessageBackgroundColor
        
        static let `default` = Self(
            id: "",
            replyId: "",
            message: NSAttributedString(string: ""),
            messageReply: NSAttributedString(string: ""),
            backgroundColor: .failed
        )
        
        func makeReplyContent() -> NSAttributedString {
            return message
        }
    }
}
