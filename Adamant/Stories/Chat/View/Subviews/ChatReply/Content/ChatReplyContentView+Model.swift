//
//  ChatReplyContentView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatReplyContentView {
    struct Model: Equatable {
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
    }
}
