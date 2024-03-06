//
//  ChatMediaContainerView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

extension ChatMediaContainerView {
    struct Model: ChatReusableViewModelProtocol, MessageModel {
        let id: String
        let isFromCurrentSender: Bool
        let reactions: Set<Reaction>?
        var content: ChatMediaContentView.Model
        let address: String
        let opponentAddress: String
        
        static let `default` = Self(
            id: "",
            isFromCurrentSender: true,
            reactions: nil,
            content: .default,
            address: "",
            opponentAddress: ""
        )
        
        func makeReplyContent() -> NSAttributedString {
            return ChatMessageFactory.markdownParser.parse("File")
        }
    }
}
