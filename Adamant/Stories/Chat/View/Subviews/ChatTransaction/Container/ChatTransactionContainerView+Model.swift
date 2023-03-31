//
//  ChatTransactionContainerView+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension ChatTransactionContainerView {
    struct Model: Equatable, MessageModel {
        let id: String
        let isFromCurrentSender: Bool
        let content: ChatTransactionContentView.Model
        var status: TransactionStatus
        
        static let `default` = Self(
            id: "",
            isFromCurrentSender: true,
            content: .default,
            status: .notInitiated
        )
        
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
