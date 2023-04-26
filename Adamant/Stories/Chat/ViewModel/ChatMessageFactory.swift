//
//  ChatMessageFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import MarkdownKit
import MessageKit

struct ChatMessageFactory {
    private let richMessageProviders: [String: RichMessageProvider]
    
    init(richMessageProviders: [String: RichMessageProvider]) {
        self.richMessageProviders = richMessageProviders
    }
    
    func makeMessage(
        _ transaction: ChatTransaction,
        expireDate: inout Date?,
        currentSender: SenderType,
        dateHeaderOn: Bool,
        topSpinnerOn: Bool
    ) -> ChatMessage {
        let sentDate = transaction.sentDate ?? .now
        let senderModel = ChatSender(transaction: transaction)
        let isFromCurrentSender = currentSender.senderId == senderModel.senderId

        let status = ChatMessage.Status(
            messageStatus: transaction.statusEnum,
            blockId: transaction.blockId
        )
        
        let backgroundColor = getBackgroundColor(
            isFromCurrentSender: isFromCurrentSender,
            status: status
        )
        
        return .init(
            id: transaction.chatMessageId ?? "",
            sentDate: sentDate,
            senderModel: senderModel,
            status: status,
            content: makeContent(
                transaction,
                isFromCurrentSender: currentSender.senderId == senderModel.senderId,
                backgroundColor: backgroundColor
            ),
            backgroundColor: backgroundColor,
            bottomString: makeBottomString(
                sentDate: sentDate,
                status: status,
                expireDate: &expireDate
            ).map { .init(string: $0) },
            dateHeader: dateHeaderOn
                ? makeDateHeader(sentDate: sentDate)
                : nil,
            topSpinnerOn: topSpinnerOn
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
            .strikethrough
        ],
        customElements: [
            MarkdownSimpleAdm(),
            MarkdownLinkAdm(),
            MarkdownAdvancedAdm(
                font: .adamantChatDefault,
                color: .adamant.active
            ),
            MarkdownCodeAdamant(
                font: .adamantCodeDefault,
                textHighlightColor: .adamant.codeBlockText,
                textBackgroundColor: .adamant.codeBlock
            )
        ]
    )
    
    func makeContent(
        _ transaction: ChatTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        switch transaction {
        case let transaction as MessageTransaction:
            return makeContent(transaction)
        case let transaction as RichMessageTransaction:
            return makeContent(
                transaction,
                isFromCurrentSender: isFromCurrentSender,
                backgroundColor: backgroundColor
            )
        case let transaction as TransferTransaction:
            return makeContent(
                transaction,
                isFromCurrentSender: isFromCurrentSender,
                backgroundColor: backgroundColor
            )
        default:
            return .default
        }
    }
    
    func makeContent(_ transaction: MessageTransaction) -> ChatMessage.Content {
        transaction.message.map {
            .message(.init(string: Self.markdownParser.parse($0)))
        } ?? .default
    }
    
    func makeContent(
        _ transaction: RichMessageTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        guard let transfer = transaction.transfer else { return .default }
        let id = transaction.chatMessageId ?? ""
        
        return .transaction(.init(value: .init(
            id: id,
            isFromCurrentSender: isFromCurrentSender,
            content: .init(
                id: id,
                title: isFromCurrentSender
                    ? .adamantLocalized.chat.transactionSent
                    : .adamantLocalized.chat.transactionReceived,
                icon: richMessageProviders[transfer.type]?.tokenLogo ?? .init(),
                amount: AdamantBalanceFormat.full.format(transfer.amount),
                currency: richMessageProviders[transfer.type]?.tokenSymbol ?? "",
                date: transaction.sentDate?.humanizedDateTime(withWeekday: false) ?? "",
                comment: transfer.comments,
                backgroundColor: backgroundColor
            ),
            status: transaction.transactionStatus ?? .notInitiated
        )))
    }
    
    func makeContent(
        _ transaction: TransferTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        let id = transaction.chatMessageId ?? ""
        
        return .transaction(.init(value: .init(
            id: id,
            isFromCurrentSender: isFromCurrentSender,
            content: .init(
                id: id,
                title: isFromCurrentSender
                    ? .adamantLocalized.chat.transactionSent
                    : .adamantLocalized.chat.transactionReceived,
                icon: AdmWalletService.currencyLogo,
                amount: AdamantBalanceFormat.full.format(
                    (transaction.amount ?? .zero) as Decimal
                ),
                currency: AdmWalletService.currencySymbol,
                date: transaction.sentDate?.humanizedDateTime(withWeekday: false) ?? "",
                comment: transaction.comment,
                backgroundColor: backgroundColor
            ),
            status: transaction.statusEnum.toTransactionStatus()
        )))
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
    
    func getBackgroundColor(
        isFromCurrentSender: Bool,
        status: ChatMessage.Status
    ) -> ChatMessageBackgroundColor {
        guard isFromCurrentSender else {
            return .opponent
        }
        
        switch status {
        case .delivered:
            return .delivered
        case .pending:
            return .pending
        case .failed:
            return .failed
        }
    }
    
    func makeDateHeader(sentDate: Date) -> ComparableAttributedString {
        .init(string: .init(
            string: sentDate.humanizedDay(),
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.adamant.secondary
            ]
        ))
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
