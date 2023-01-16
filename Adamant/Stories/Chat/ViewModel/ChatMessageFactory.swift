//
//  ChatMessageFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct ChatMessageFactory {
    private let richMessageProviders: [String: RichMessageProvider]
    
    init(richMessageProviders: [String: RichMessageProvider]) {
        self.richMessageProviders = richMessageProviders
    }
    
    func makeMessage(_ transaction: ChatTransaction) -> ChatMessage {
        .init(
            messageId: transaction.chatMessageId ?? "",
            sentDate: transaction.date.map { $0 as Date } ?? .init(),
            senderModel: .init(transaction: transaction),
            status: .init(
                messageStatus: transaction.statusEnum,
                blockId: transaction.blockId
            ),
            content: makeContent(transaction)
        )
    }
}

private extension ChatMessageFactory {
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
        transaction.message.map { .message($0) } ?? .default
    }
    
    func makeContent(_ transaction: RichMessageTransaction) -> ChatMessage.Content {
        guard let transfer = transaction.transfer else { return .default }
        
        return .transaction(.init(
            icon: richMessageProviders[transfer.type]?.tokenLogo ?? .init(),
            amount: transfer.amount,
            currency: richMessageProviders[transfer.type]?.tokenSymbol ?? "",
            comment: transfer.comments,
            status: transaction.transactionStatus ?? .notInitiated
        ))
    }
    
    func makeContent(_ transaction: TransferTransaction) -> ChatMessage.Content {
        .transaction(.init(
            icon: AdmWalletService.currencyLogo,
            amount: (transaction.amount ?? .zero) as Decimal,
            currency: AdmWalletService.currencySymbol,
            comment: transaction.comment,
            status: transaction.statusEnum.toTransactionStatus()
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
