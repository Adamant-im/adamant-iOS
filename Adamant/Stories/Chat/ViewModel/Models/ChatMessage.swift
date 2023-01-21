//
//  ChatMessage.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import MarkdownKit

struct ChatMessage: Equatable {
    let messageId: String
    let sentDate: Date
    let senderModel: ChatSender
    let status: Status
    let content: Content
    let bottomString: NSAttributedString?
    
    static let `default` = Self(
        messageId: "",
        sentDate: .init(),
        senderModel: .default,
        status: .failed,
        content: .default,
        bottomString: nil
    )
}

extension ChatMessage {
    enum Status: Equatable {
        case delivered(blockchain: Bool)
        case pending
        case failed
    }
    
    enum Content: Equatable {
        case message(String)
        case transaction(Transaction)
        
        static let `default` = Self.message("")
    }
    
    struct Transaction: Equatable {
        let icon: UIImage
        let amount: Decimal
        let currency: String
        let comment: String?
        let status: TransactionStatus
    }
}

extension ChatMessage: MessageType {
    var sender: SenderType {
        senderModel
    }
    
    var kind: MessageKind {
        switch content {
        case let .message(text):
            let markdownText = markdownParser.parse(text)
            return .attributedText(markdownText)
        case let .transaction(model):
            return .custom(model)
        }
    }
    
    var markdownParser: MarkdownParser {
        return MarkdownParser(font: UIFont.adamantChatDefault,
                              color: UIColor.adamant.primary,
                              enabledElements: [
                                .header,
                                .list,
                                .quote,
                                .bold,
                                .italic,
                                .code,
                                .strikethrough
                              ],
                              customElements: [
                                MarkdownSimpleAdm(),
                                MarkdownLinkAdm(),
                                MarkdownAdvancedAdm(
                                    font: UIFont.adamantChatDefault,
                                    color: UIColor.adamant.active
                                )
                              ]
        )
    }
}

// ChatMessage must be the only implementation of MessageType
extension MessageType {
    var fullModel: ChatMessage {
        if let message = self as? ChatMessage {
            return message
        } else {
            assertionFailure("Incorrect type")
            return .default
        }
    }
}
