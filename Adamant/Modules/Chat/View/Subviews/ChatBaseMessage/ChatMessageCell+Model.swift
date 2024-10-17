//
//  ChatMessageCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatMessageCell {
    struct Model: ChatReusableViewModelProtocol, MessageModel, @unchecked Sendable {
        let id: String
        let text: NSAttributedString
        let backgroundColor: ChatMessageBackgroundColor
        let isFromCurrentSender: Bool
        let reactions: Set<Reaction>?
        let address: String
        let opponentAddress: String
        let isFake: Bool
        var isHidden: Bool
        
        static var `default`: Self {
            Self(
                id: "",
                text: NSAttributedString(string: ""),
                backgroundColor: .failed,
                isFromCurrentSender: false,
                reactions: nil,
                address: "",
                opponentAddress: "",
                isFake: false,
                isHidden: false
            )
        }
        
        func makeReplyContent() -> NSAttributedString {
            return text
        }
    }
}
