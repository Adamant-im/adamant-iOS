//
//  ChatMessageReplyCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatMessageReplyCell {
    struct Model: ChatReusableViewModelProtocol, MessageModel, @unchecked Sendable {
        let id: String
        let replyId: String
        let message: NSAttributedString
        let messageReply: NSAttributedString
        let backgroundColor: ChatMessageBackgroundColor
        let isFromCurrentSender: Bool
        let reactions: Set<Reaction>?
        let address: String
        let opponentAddress: String
        var isHidden: Bool
        
        static var `default`: Self {
            Self(
                id: "",
                replyId: "",
                message: NSAttributedString(string: ""),
                messageReply: NSAttributedString(string: ""),
                backgroundColor: .failed,
                isFromCurrentSender: false,
                reactions: nil,
                address: "",
                opponentAddress: "",
                isHidden: false
            )
        }
        
        func makeReplyContent() -> NSAttributedString {
            return message
        }
    }
}

extension ChatMessageReplyCell.Model {
    @MainActor
    func contentHeight(for width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: .infinity)
        
        let messageHeight = message.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height
        
        return verticalInsets * 2
        + verticalStackSpacing
        + messageHeight
        + ChatMessageReplyCell.replyViewHeight
    }
}

private let verticalStackSpacing: CGFloat = 12
private let verticalInsets: CGFloat = 8
