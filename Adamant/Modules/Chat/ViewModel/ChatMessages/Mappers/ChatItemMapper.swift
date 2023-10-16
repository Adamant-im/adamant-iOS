//
//  ChatItemMapper.swift
//  Adamant
//
//  Created by Andrew G on 09.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import ChatKit
import MarkdownKit
import CommonKit

struct ChatItemMapper {
    let richMessageProviders: [String: RichMessageProvider]
    let markdownParser: MarkdownParser
    let markdownReplyParser: MarkdownParser
    let avatarService: AvatarService
    
    func map(transaction: ChatTransaction) -> ChatItemModel {
        switch transaction {
        case let transaction as MessageTransaction:
            return map(messageTransaction: transaction)
        case let transaction as RichMessageTransaction:
            return map(richTransaction: transaction)
        case let transaction as TransferTransaction:
            return map(transferTransaction: transaction)
        default:
            return mapUnknownTransaction(transaction)
        }
    }
}

private extension ChatItemMapper {
    func map(messageTransaction: MessageTransaction) -> ChatItemModel {
        let reactions = messageTransaction.reactions.map { map(reactions: $0) }
        let attributedString = markdownParser.parse(messageTransaction.message ?? .empty)
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = messageLineSpacing
        
        mutableString.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: .zero, length: attributedString.length)
        )
        
        return .message(.init(
            id: messageTransaction.txId,
            content: .init(
                text: mutableString,
                reply: nil,
                status: messageTransaction.chatItemStatus
            ),
            topString: makeMessageTopString(chatTransaction: messageTransaction),
            bottomString: .init(),
            reactions: messageTransaction.reactions.map { map(reactions: $0) } ?? .default
        ))
    }
    
    func map(richTransaction: RichMessageTransaction) -> ChatItemModel {
        if richTransaction.additionalType == .reply, !richTransaction.isTransferReply() {
            return map(richReplyTransaction: richTransaction)
        } else {
            return map(richTransferTransaction: richTransaction)
        }
    }
    
    func map(richTransferTransaction transaction: RichMessageTransaction) -> ChatItemModel {
        let reactionsSet = transaction.richContent?[RichContentKeys.react.reactions] as? Set<Reaction>
        let reactions = reactionsSet.map { map(reactions: $0) } ?? .default
        
        return .transaction(.init(
            id: transaction.txId,
            transactionStatus: transaction.transactionStatus?.chatTransactionStatus ?? .none,
            reactions: reactions,
            content: transaction.transfer.map { transfer in
                .init(
                    reply: makeReplyModel(
                        id: transaction.getRichValue(for: RichContentKeys.reply.replyToId),
                        message: transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage)
                    ),
                    title: transaction.isOutgoing
                        ? .adamant.chat.transactionSent
                        : .adamant.chat.transactionReceived,
                    icon: richMessageProviders[transfer.type]?.tokenLogo ?? .init(),
                    amount: AdamantBalanceFormat.full.format(transfer.amount),
                    currency: richMessageProviders[transfer.type]?.tokenSymbol ?? .empty,
                    date: .empty,
                    comment: transfer.comments,
                    status: transaction.chatItemStatus,
                    onTap: .default
                )
            } ?? .default,
            statusUpdateAction: .default
        ))
    }
    
    func map(richReplyTransaction transaction: RichMessageTransaction) -> ChatItemModel {
        let message = transaction.getRichValue(for: RichContentKeys.reply.replyMessage) ?? .empty
        let reactionsSet = transaction.richContent?[RichContentKeys.react.reactions] as? Set<Reaction>
        
        return .message(.init(
            id: transaction.txId,
            content: .init(
                text: markdownParser.parse(message),
                reply: makeReplyModel(
                    id: transaction.getRichValue(for: RichContentKeys.reply.replyToId),
                    message: transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage)
                ),
                status: transaction.chatItemStatus
            ),
            topString: makeMessageTopString(chatTransaction: transaction),
            bottomString: .init(),
            reactions: reactionsSet.map { map(reactions: $0) } ?? .default
        ))
    }
    
    func map(transferTransaction transaction: TransferTransaction) -> ChatItemModel {
        .transaction(.init(
            id: transaction.txId,
            transactionStatus: transaction.transactionStatus?.chatTransactionStatus ?? .none,
            reactions: transaction.reactions.map { map(reactions: $0) } ?? .default,
            content: .init(
                reply: makeReplyModel(
                    id: transaction.replyToId,
                    message: transaction.decodedReplyMessage
                ),
                title: transaction.isOutgoing
                    ? .adamant.chat.transactionSent
                    : .adamant.chat.transactionReceived,
                icon: AdmWalletService.currencyLogo,
                amount: AdamantBalanceFormat.full.format((transaction.amount ?? .zero) as Decimal),
                currency: AdmWalletService.currencySymbol,
                date: transaction.sentDate?.humanizedDateTime(withWeekday: false) ?? .empty,
                comment: transaction.comment,
                status: transaction.chatItemStatus,
                onTap: .default
            ),
            statusUpdateAction: .default
        ))
    }
    
    func map(reaction: Reaction) -> ChatReactionModel {
        .init(
            emoji: reaction.reaction ?? "❓",
            image: avatarService.avatar(for: reaction.sender, size: reactionAvatarSize),
            onTap: .default
        )
    }
    
    func map(reactions: Set<Reaction>) -> ChatReactionsStackModel {
        let reactions = reactions.sorted { $0.sender > $1.sender }
        let firstReaction = reactions.first
        let secondReaction = reactions.first == reactions.last ? nil : reactions.last
        
        return .init(
            first: firstReaction.map { map(reaction: $0) },
            second: secondReaction.map { map(reaction: $0) }
        )
    }
    
    func makeReplyModel(id: String?, message: String?) -> ChatReplyModel? {
        guard
            let id = id,
            let message = message
        else { return nil }
        
        return .init(
            replyText: markdownReplyParser.parse(message).resolveLinkColor(),
            onTap: .init(id: id) {}
        )
    }
    
    func makeMessageTopString(chatTransaction: ChatTransaction) -> NSAttributedString? {
        guard chatTransaction.statusEnum == .failed else { return nil }
        
        return .init(
            string: .adamant.chat.failToSend,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.adamant.primary
            ]
        )
    }
    
    func mapUnknownTransaction(_ transaction: ChatTransaction) -> ChatItemModel {
        .message(.init(
            id: transaction.txId,
            content: .default,
            topString: nil,
            bottomString: .init(),
            reactions: .default
        ))
    }
}

private extension TransactionStatus {
    var chatTransactionStatus: ChatTransactionModel.Status {
        switch self {
        case .notInitiated:
            return .none
        case .pending, .registered, .noNetwork, .noNetworkFinal:
            return .pending
        case .success:
            return .success
        case .failed:
            return .failed
        case .inconsistent:
            return .warning
        }
    }
}

private extension ChatTransaction {
    var chatItemStatus: ChatItemStatus {
        switch statusEnum {
        case .pending:
            return .pending
        case .delivered:
            return isOutgoing
                ? .sent
                : .received
        case .failed:
            return .failed
        }
    }
}

private let reactionAvatarSize: CGFloat = 50
private let messageLineSpacing: CGFloat = 1.15
