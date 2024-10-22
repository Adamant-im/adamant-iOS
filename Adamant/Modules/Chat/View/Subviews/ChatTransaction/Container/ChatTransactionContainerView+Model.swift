//
//  ChatTransactionContainerView+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension ChatTransactionContainerView {
    struct Model: ChatReusableViewModelProtocol, MessageModel, @unchecked Sendable {
        let id: String
        let isFromCurrentSender: Bool
        var content: ChatTransactionContentView.Model
        let status: TransactionStatus
        let reactions: Set<Reaction>?
        let address: String
        let opponentAddress: String
        
        static var `default`: Self {
            Self(
                id: "",
                isFromCurrentSender: true,
                content: .default,
                status: .notInitiated,
                reactions: nil,
                address: "",
                opponentAddress: ""
            )
        }
        
        func makeReplyContent() -> NSAttributedString {
            let commentRaw = content.comment ?? ""
            let comment = commentRaw.isEmpty
            ? commentRaw
            : ": \(commentRaw)"
            
            let content = "\(content.title) \(content.currency) \(content.amount)\(comment)"
            
            return ChatMessageFactory.markdownParser.parse(content)
        }
    }
}
