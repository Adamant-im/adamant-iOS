//
//  ChatMessagesListFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 08.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import Combine

actor ChatMessagesListFactory {
    typealias ProcessTransaction = (_ id: String) -> Void
    
    private let chatMessageFactory: ChatMessageFactory
    private let didTapTransfer: ProcessTransaction
    private let forceUpdateStatusAction: ProcessTransaction
    
    init(
        chatMessageFactory: ChatMessageFactory,
        didTapTransfer: @escaping ProcessTransaction,
        forceUpdateStatusAction: @escaping ProcessTransaction
    ) {
        self.chatMessageFactory = chatMessageFactory
        self.didTapTransfer = didTapTransfer
        self.forceUpdateStatusAction = forceUpdateStatusAction
    }
    
    func makeMessages(
        transactions: [ChatTransaction],
        sender: ChatSender,
        isNeedToLoadMoreMessages: Bool,
        expirationTimestamp minExpTimestamp: inout TimeInterval?
    ) -> [ChatMessage] {
        assert(!Thread.isMainThread, "Do not process messages on main thread")
        
        return transactions.enumerated().map { index, transaction in
            var expTimestamp: TimeInterval?
            let message = makeMessage(
                transaction,
                sender: sender,
                dateHeaderOn: isNeedToDisplayDateHeader(index: index, transactions: transactions),
                topSpinnerOn: isNeedToLoadMoreMessages && index == .zero,
                willExpireAfter: &expTimestamp
            )
            
            if let timestamp = expTimestamp, timestamp < minExpTimestamp ?? .greatestFiniteMagnitude {
                minExpTimestamp = timestamp
            }
            
            return message
        }
    }
}

private extension ChatMessagesListFactory {
    func makeMessage(
        _ transaction: ChatTransaction,
        sender: SenderType,
        dateHeaderOn: Bool,
        topSpinnerOn: Bool,
        willExpireAfter: inout TimeInterval?
    ) -> ChatMessage {
        var expireDate: Date?
        let message = chatMessageFactory.makeMessage(
            transaction,
            expireDate: &expireDate,
            currentSender: sender,
            dateHeaderOn: dateHeaderOn,
            topSpinnerOn: topSpinnerOn,
            didTapTransfer: didTapTransfer,
            forceUpdateStatusAction: forceUpdateStatusAction
        )
        
        willExpireAfter = expireDate?.timeIntervalSince1970
        return message
    }
}

private func isNeedToDisplayDateHeader(
    index: Int,
    transactions: [ChatTransaction]
) -> Bool {
    guard transactions[index].sentDate != .adamantNullDate else { return false }
    guard index > .zero else { return true }
    
    let timeIntervalFromLastMessage = transactions[index].sentDate
        .timeIntervalSince(transactions[index - 1].sentDate)
    
    return timeIntervalFromLastMessage >= dateHeaderTimeInterval
}

private let dateHeaderTimeInterval: TimeInterval = 3600
