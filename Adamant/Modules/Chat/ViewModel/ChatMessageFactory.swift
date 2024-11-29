//
//  ChatMessageFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import MarkdownKit
import MessageKit
import CommonKit
import FilesStorageKit

struct ChatMessageFactory: Sendable {
    private let walletServiceCompose: WalletServiceCompose
    
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
            ),
            MarkdownFileRaw(emoji: "📸", font: .adamantChatFileRawDefault),
            MarkdownFileRaw(emoji: "📄", font: .adamantChatFileRawDefault)
        ]
    )
    
    static let markdownReplyParser = MarkdownParser(
        font: .adamantChatReplyDefault,
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
            ),
            MarkdownFileRaw(emoji: "📸", font: .adamantChatFileRawDefault),
            MarkdownFileRaw(emoji: "📄", font: .adamantChatFileRawDefault)
        ]
    )
    
    init(walletServiceCompose: WalletServiceCompose) {
        self.walletServiceCompose = walletServiceCompose
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
        
        let content = makeContent(
            transaction,
            isFromCurrentSender: currentSender.senderId == senderModel.senderId,
            backgroundColor: backgroundColor
        )
        
        return .init(
            id: transaction.chatMessageId ?? "",
            sentDate: sentDate,
            senderModel: senderModel,
            status: status,
            content: content,
            backgroundColor: backgroundColor,
            bottomString: makeBottomString(
                sentDate: sentDate,
                status: status,
                expireDate: &expireDate,
                content: content
            ).map { .init(string: $0) },
            dateHeader: makeDateHeader(sentDate: sentDate),
            topSpinnerOn: topSpinnerOn, 
            dateHeaderIsHidden: !dateHeaderOn
        )
    }
}

private extension ChatMessageFactory {
    func makeContent(
        _ transaction: ChatTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        switch transaction {
        case let transaction as MessageTransaction:
            return makeContent(
                transaction,
                isFromCurrentSender: isFromCurrentSender,
                backgroundColor: backgroundColor
            )
        case let transaction as RichMessageTransaction:
            if transaction.additionalType == .reply,
               !transaction.isTransferReply(),
               !transaction.isFileReply() {
                return makeReplyContent(
                    transaction,
                    isFromCurrentSender: isFromCurrentSender,
                    backgroundColor: backgroundColor
                )
            }
            
            if transaction.additionalType == .file ||
               (transaction.additionalType == .reply &&
                transaction.isFileReply()) {
                return makeFileContent(
                    transaction,
                    isFromCurrentSender: isFromCurrentSender,
                    backgroundColor: backgroundColor
                )
            }
            
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
    
    func makeContent(
        _ transaction: MessageTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        transaction.message.map {
            let text = makeAttributed($0)
            let reactions = transaction.reactions
            
            let address = transaction.isOutgoing
            ? transaction.senderAddress
            : transaction.recipientAddress
            
            let opponentAddress = transaction.isOutgoing
            ? transaction.recipientAddress
            : transaction.senderAddress
            
            return .message(.init(
                value: .init(
                    id: transaction.txId,
                    text: text,
                    backgroundColor: backgroundColor,
                    isFromCurrentSender: isFromCurrentSender,
                    reactions: reactions,
                    address: address,
                    opponentAddress: opponentAddress,
                    isFake: transaction.isFake,
                    isHidden: false
                )
            ))
        } ?? .default
    }
    
    func makeReplyContent(
        _ transaction: RichMessageTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        guard let replyId = transaction.getRichValue(for: RichContentKeys.reply.replyToId),
              let replyMessageRaw = transaction.getRichValue(for: RichContentKeys.reply.replyMessage)
        else {
            return .default
        }
        
        let replyMessage = makeAttributed(replyMessageRaw)
        let decodedMessage = transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage) ?? "..."
        let decodedMessageMarkDown = Self.markdownReplyParser.parse(decodedMessage).resolveLinkColor()
        let reactions = transaction.richContent?[RichContentKeys.react.reactions] as? Set<Reaction>
        
        let address = transaction.isOutgoing
        ? transaction.senderAddress
        : transaction.recipientAddress
        
        let opponentAddress = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        return .reply(.init(
            value: .init(
                id: transaction.txId,
                replyId: replyId,
                message: replyMessage,
                messageReply: decodedMessageMarkDown,
                backgroundColor: backgroundColor,
                isFromCurrentSender: isFromCurrentSender,
                reactions: reactions,
                address: address,
                opponentAddress: opponentAddress,
                isHidden: false
            )
        ))
    }
    
    func makeContent(
        _ transaction: RichMessageTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        guard let transfer = transaction.transfer else { return .default }
        let id = transaction.chatMessageId ?? ""
        
        let decodedMessage = transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage) ?? "..."
        let decodedMessageMarkDown = Self.markdownReplyParser.parse(decodedMessage).resolveLinkColor()
        let replyId = transaction.getRichValue(for: RichContentKeys.reply.replyToId) ?? ""
        let reactions = transaction.richContent?[RichContentKeys.react.reactions] as? Set<Reaction>
        
        let address = transaction.isOutgoing
        ? transaction.senderAddress
        : transaction.recipientAddress
        
        let opponentAddress = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        let coreService = walletServiceCompose.getWallet(by: transfer.type)?.core
        let defaultIcon: UIImage = .asset(named: "no-token")?.withTintColor(.adamant.primary) ?? .init()
        
        return .transaction(.init(value: .init(
            id: id,
            isFromCurrentSender: isFromCurrentSender,
            content: .init(
                id: id,
                title: isFromCurrentSender
                    ? .adamant.chat.transactionSent
                    : .adamant.chat.transactionReceived,
                icon: coreService?.tokenLogo ?? defaultIcon,
                amount: AdamantBalanceFormat.full.format(transfer.amount),
                currency: coreService?.tokenSymbol ?? .adamant.transfer.unknownToken,
                date: transaction.sentDate?.humanizedDateTime(withWeekday: false) ?? "",
                comment: transfer.comments,
                backgroundColor: backgroundColor,
                isReply: transaction.isTransferReply(),
                replyMessage: decodedMessageMarkDown,
                replyId: replyId,
                isHidden: false
            ),
            status: transaction.transactionStatus ?? .notInitiated,
            reactions: reactions,
            address: address,
            opponentAddress: opponentAddress
        )))
    }
    
    func makeFileContent(
        _ transaction: RichMessageTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        let id = transaction.chatMessageId ?? ""
        
        let files: [[String: Any]] = transaction.getRichValue(for: RichContentKeys.file.files) ?? [[:]]
        
        let decodedMessage = decodeMessage(transaction)
        let storageData: [String: Any] = transaction.getRichValue(for: RichContentKeys.file.storage) ?? [:]
        let storage = RichMessageFile.Storage(storageData).id
        
        let commentRaw = transaction.getRichValue(for: RichContentKeys.file.comment) ?? .empty
        let replyId = transaction.getRichValue(for: RichContentKeys.reply.replyToId) ?? .empty
        let reactions = transaction.richContent?[RichContentKeys.react.reactions] as? Set<Reaction>
        let comment = makeAttributed(commentRaw)
        
        let address = transaction.isOutgoing
        ? transaction.senderAddress
        : transaction.recipientAddress
        
        let opponentAddress = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        let chatFiles = makeChatFiles(
            from: files,
            isFromCurrentSender: isFromCurrentSender,
            storage: storage
        )
        
        let isMediaFilesOnly = chatFiles.allSatisfy {
            $0.fileType == .image || $0.fileType == .video
        }
        
        let fileModel = ChatMediaContentView.FileModel(
            messageId: id,
            files: chatFiles,
            isMediaFilesOnly: isMediaFilesOnly,
            isFromCurrentSender: isFromCurrentSender,
            txStatus: transaction.statusEnum
        )
        
        return .file(.init(value: .init(
            id: id,
            isFromCurrentSender: isFromCurrentSender,
            reactions: reactions,
            content: .init(
                id: id,
                fileModel: fileModel,
                isHidden: false,
                isFromCurrentSender: isFromCurrentSender,
                isReply: transaction.isFileReply(),
                replyMessage: decodedMessage,
                replyId: replyId,
                comment: comment,
                backgroundColor: backgroundColor
            ),
            address: address,
            opponentAddress: opponentAddress, 
            txStatus: transaction.statusEnum,
            status: .failed
        )))
    }
    
    func makeAttributed(_ text: String) -> NSMutableAttributedString {
        let attributedString = Self.markdownParser.parse(text)
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        mutableAttributedString.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: .zero, length: attributedString.length)
        )
        
        return mutableAttributedString
    }
    
    func decodeMessage(_ transaction: RichMessageTransaction) -> NSMutableAttributedString {
        let decodedMessage = transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage) ?? "..."
        return Self.markdownReplyParser.parse(decodedMessage).resolveLinkColor()
    }
    
    func makeChatFiles(
        from files: [[String: Any]],
        isFromCurrentSender: Bool,
        storage: String
    ) -> [ChatFile] {
        return files.map {
            let file = RichMessageFile.File($0)
            let fileType = FileType(raw: file.extension ?? .empty) ?? .other
            
            return ChatFile(
                file: file,
                previewImage: nil,
                downloadStatus: .default,
                isUploading: false,
                isCached: false,
                storage: storage,
                nonce: file.nonce,
                isFromCurrentSender: isFromCurrentSender,
                fileType: fileType,
                progress: nil,
                isPreviewDownloadAllowed: false,
                isFullMediaDownloadAllowed: false
            )
        }
    }
    
    func makeContent(
        _ transaction: TransferTransaction,
        isFromCurrentSender: Bool,
        backgroundColor: ChatMessageBackgroundColor
    ) -> ChatMessage.Content {
        let id = transaction.chatMessageId ?? ""
        
        let decodedMessage = transaction.decodedReplyMessage ?? "..."
        let decodedMessageMarkDown = Self.markdownReplyParser.parse(decodedMessage).resolveLinkColor()
        let replyId = transaction.replyToId ?? ""
        let reactions = transaction.reactions
        
        let address = transaction.isOutgoing
        ? transaction.senderAddress
        : transaction.recipientAddress
        
        let opponentAddress = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        return .transaction(.init(value: .init(
            id: id,
            isFromCurrentSender: isFromCurrentSender,
            content: .init(
                id: id,
                title: isFromCurrentSender
                    ? .adamant.chat.transactionSent
                    : .adamant.chat.transactionReceived,
                icon: AdmWalletService.currencyLogo,
                amount: AdamantBalanceFormat.full.format(
                    (transaction.amount ?? .zero) as Decimal
                ),
                currency: AdmWalletService.currencySymbol,
                date: transaction.sentDate?.humanizedDateTime(withWeekday: false) ?? "",
                comment: transaction.comment,
                backgroundColor: backgroundColor,
                isReply: !replyId.isEmpty,
                replyMessage: decodedMessageMarkDown,
                replyId: replyId,
                isHidden: false
            ),
            status: transaction.statusEnum.toTransactionStatus(),
            reactions: reactions,
            address: address,
            opponentAddress: opponentAddress
        )))
    }
    
    func makeBottomString(
        sentDate: Date,
        status: ChatMessage.Status,
        expireDate: inout Date?,
        content: ChatMessage.Content
    ) -> NSAttributedString? {
        switch content {
        case .file, .message, .reply:
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
        case .transaction:
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
        attachment.image = .asset(named: "status_pending")
        attachment.image?.withTintColor(.adamant.secondary)
        attachment.bounds = CGRect(x: .zero, y: -1, width: 10, height: 10)
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
            string: sentDate.humanizedDay(useTimeFormat: false),
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

private let lineSpacing: CGFloat = 1.15
