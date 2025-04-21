//
//  ChatMessagesListFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 08.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation
import MessageKit
import OrderedCollections

actor ChatMessagesListFactory {
    private let chatMessageFactory: ChatMessageFactory
    private let coreDataRelationMapper: CoreDataRealationMapperProtocol

    init(chatMessageFactory: ChatMessageFactory, coreDataRelationMapper: CoreDataRealationMapperProtocol) {
        self.chatMessageFactory = chatMessageFactory
        self.coreDataRelationMapper = coreDataRelationMapper
    }

    func makeMessages(
        transactions: [ChatTransaction],
        sender: ChatSender,
        isNeedToLoadMoreMessages: Bool,
        expirationTimestamp minExpTimestamp: inout TimeInterval?
    ) async -> ([ChatMessage], OrderedSet<String>, OrderedSet<String>) {
        assert(!Thread.isMainThread, "Do not process messages on main thread")

        var processedTransactionIds: OrderedSet<String> = []

        await withTaskGroup(of: String?.self) { group in
            for chatTransaction in transactions {
                guard let transaction = chatTransaction as? RichMessageTransaction,
                      transaction.additionalType == .reaction,
                      transaction.isUnread
                else { continue }

                group.addTask { [weak self] in
                    await self?.coreDataRelationMapper.mapReactionRelationship(transaction: transaction)
                }
            }

            for await result in group {
                if let id = result {
                    processedTransactionIds.append(id)
                }
            }
        }
        let transactionsWithoutReact = transactions.filter { chatTransaction in
            guard let transaction = chatTransaction as? RichMessageTransaction,
                transaction.additionalType == .reaction
            else { return true }

            return false
        }
        let transactionIdsWithoutReact: OrderedSet<String> = OrderedSet(
            transactionsWithoutReact
                .filter { $0.isUnread }
                .compactMap { $0.transactionId }
        )
        let messages = transactionsWithoutReact.enumerated().map { index, transaction in
            var expTimestamp: TimeInterval?
            let message = makeMessage(
                transaction,
                sender: sender,
                dateHeaderOn: isNeedToDisplayDateHeader(
                    index: index,
                    transactions: transactionsWithoutReact
                ),
                topSpinnerOn: isNeedToLoadMoreMessages && index == .zero,
                willExpireAfter: &expTimestamp
            )

            if let timestamp = expTimestamp, timestamp < minExpTimestamp ?? .greatestFiniteMagnitude {
                minExpTimestamp = timestamp
            }

            return message
        }

        return (messages, processedTransactionIds, transactionIdsWithoutReact)
    }
}

extension ChatMessagesListFactory {
    fileprivate func makeMessage(
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
            topSpinnerOn: topSpinnerOn
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

    guard
        let previousDate = transactions[index - 1].sentDate,
        let currentDate = transactions[index].sentDate
    else { return false }

    return !Calendar.current.isDate(currentDate, inSameDayAs: previousDate)
}
