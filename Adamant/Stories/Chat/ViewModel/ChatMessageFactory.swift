//
//  ChatMessageFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import MarkdownKit

struct ChatMessageFactory {
    private let richMessageProviders: [String: RichMessageProvider]
    
    init(richMessageProviders: [String: RichMessageProvider]) {
        self.richMessageProviders = richMessageProviders
    }
    
    func makeMessage(
        _ transaction: ChatTransaction,
        expireDate: inout Date?
    ) -> ChatMessage {
        let sentDate = transaction.date.map { $0 as Date } ?? .init()
        let status = ChatMessage.Status(
            messageStatus: transaction.statusEnum,
            blockId: transaction.blockId
        )
        
        return .init(
            id: transaction.chatMessageId ?? "",
            sentDate: sentDate,
            senderModel: .init(transaction: transaction),
            status: status,
            content: makeContent(transaction),
            bottomString: makeBottomString(
                sentDate: sentDate,
                status: status,
                expireDate: &expireDate
            ).map { .init(string: $0) }
        )
    }
}

private extension ChatMessageFactory {
    static let markdownParser = MarkdownParser(
        font: .adamantChatDefault,
        color: .adamant.primary,
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
                font: .adamantChatDefault,
                color: .adamant.active
            )
        ]
    )
    
    func makeContent(_ transaction: ChatTransaction) -> ChatMessage.Content {
        switch transaction {
        case let transaction as MessageTransaction:
            return makeContent(transaction)
        case let transaction as RichMessageTransaction:
            return makeContent(transaction)
        case let transaction as TransferTransaction:
            return makeContent(transaction)
        default:
            return .default
        }
    }
    
    func makeContent(_ transaction: MessageTransaction) -> ChatMessage.Content {
        transaction.message.map {
            .message(.init(string: Self.markdownParser.parse($0)))
        } ?? .default
    }
    
    func makeContent(_ transaction: RichMessageTransaction) -> ChatMessage.Content {
        guard let transfer = transaction.transfer else { return .default }
        
        return .transaction(.init(
            icon: richMessageProviders[transfer.type]?.tokenLogo ?? .init(),
            amount: transfer.amount,
            currency: richMessageProviders[transfer.type]?.tokenSymbol ?? "",
            comment: transfer.comments
        ))
    }
    
    func makeContent(_ transaction: TransferTransaction) -> ChatMessage.Content {
        .transaction(.init(
            icon: AdmWalletService.currencyLogo,
            amount: (transaction.amount ?? .zero) as Decimal,
            currency: AdmWalletService.currencySymbol,
            comment: transaction.comment
        ))
    }
    
    func makeBottomString(
        sentDate: Date,
        status: ChatMessage.Status,
        expireDate: inout Date?
    ) -> NSAttributedString? {
        switch status {
        case let .delivered(blockchain):
            return makeMessageTimeString(
                sentDate: sentDate,
                blockchain: blockchain,
                expireDate: &expireDate
            )
        case .pending:
            return makePendingMessageString()
        case .failed:
            return nil
        }
    }
    
    func makeMessageTimeString(
        sentDate: Date,
        blockchain: Bool,
        expireDate: inout Date?
    ) -> NSAttributedString? {
        guard sentDate.timeIntervalSince1970 > .zero else { return nil }
        
        let prefix = blockchain ? "⚭" : nil
        let humanizedTime = sentDate.humanizedTime()
        expireDate = humanizedTime.expireIn.map { .init().addingTimeInterval($0) }
        
        let string = [prefix, humanizedTime.string]
            .compactMap { $0 }
            .joined(separator: " ")
        
        return .init(
            string: string,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption2),
                .foregroundColor: UIColor.adamant.secondary
            ]
        )
    }
    
    func makePendingMessageString() -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "status_pending")
        attachment.bounds = CGRect(x: .zero, y: -1, width: 7, height: 7)
        return NSAttributedString(attachment: attachment)
    }
}

private extension ChatMessage.Status {
    init(messageStatus: MessageStatus, blockId: String?) {
        switch messageStatus {
        case .pending:
            self = .pending
        case .delivered:
            self = .delivered(blockchain: !(blockId?.isEmpty ?? true))
        case .failed:
            self = .failed
        }
    }
}

private extension ChatSender {
    init(transaction: ChatTransaction) {
        self.init(
            senderId: transaction.senderId ?? "",
            displayName: transaction.senderId ?? ""
        )
    }
}
