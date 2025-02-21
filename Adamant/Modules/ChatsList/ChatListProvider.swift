//
//  ChatListProvider.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 17.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import MarkdownKit
import UIKit

final class ChatListProviderDependencyContainer {
    let adamantChatService: AdamantTransactionsService
    let accountService: AccountService
    let accountsProvider: AccountsProvider
    let txService: ChatTransactionService
    let adamantCore: AdamantCore
    let walletServiceCompose: WalletServiceCompose
    let avatarService: AvatarService
    let addressBookService: AddressBookService
    
    init(
        adamantChatService: AdamantTransactionsService,
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        txService: ChatTransactionService,
        adamantCore: AdamantCore,
        walletServiceCompose: WalletServiceCompose,
        avatarService: AvatarService,
        addressBookService: AddressBookService
    ) {
        self.adamantChatService = adamantChatService
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.txService = txService
        self.adamantCore = adamantCore
        self.walletServiceCompose = walletServiceCompose
        self.avatarService = avatarService
        self.addressBookService = addressBookService
    }
}

final class ChatsListProvider {
    // MARK: - Dependencies
    private let container: ChatListProviderDependencyContainer
    
    private var offset = 20
    private var loadedRoomsCount: Int?
    private var maxRoomsCount: Int = .zero
    private var cells: [NextGenChatroomCell] = []
    private lazy var cellsConfigurator: ChatListCellConfigurator = .init(container: container)
    
    init(
        container: ChatListProviderDependencyContainer
    ) {
        self.container = container
    }
    
    @MainActor
    func fetchChats(loadedRoomsCount: Int? = nil) async {
        let chats = await container.adamantChatService.getChatRooms(
            address: "U3716604363012166999",
            offset: loadedRoomsCount,
            waitsForConnectivity: true
        )
        
        guard let chats = try? chats.get() else { return }
        
        var cells: [NextGenChatroomCell] = []
        
        for chat in chats.chats! {
            guard let transaction = chat.lastTransaction,
                  let cell = cellsConfigurator.configureCellContent(transaction: transaction) else { continue }
            cells.append(cell)
        }
    }
}

struct ChatListCellConfigurator {
    private let container: ChatListProviderDependencyContainer
    
    init(
        container: ChatListProviderDependencyContainer
    ) {
        self.container = container
    }
    
    @MainActor
    func configureCellContent(transaction: Transaction) -> NextGenChatroomCell? {
        let avatarMapper: PartnerAvatarMapper = .init(container: container)
        let messageMapper: LastMessageMapper = .init(container: container)
        let nameMapper: NameMapper = .init(container: container)
        
        let avatar = avatarMapper.getAvatar(transaction: transaction)
        let lastMessageText = messageMapper.getMessageFrom(transaction: transaction)
        let nameTitle = nameMapper.getName(transaction: transaction)
        print("==// 2", transaction.id)
        
        return .init(
            avatar: avatar,
            dateText: transaction.date.humanizedDay(useTimeFormat: true),
            accountText: nameTitle?.checkAndReplaceSystemWallets(),
            lastMessageText: lastMessageText,
            hasUnreadMessages: true
        )
    }
}

struct NameMapper {
    private let container: ChatListProviderDependencyContainer
    
    init(
        container: ChatListProviderDependencyContainer
    ) {
        self.container = container
    }
    
    @MainActor
    func getName(transaction: Transaction) -> String? {
        let isOutMessage = container.accountService.account?.address == transaction.senderId
        let address = isOutMessage ? transaction.recipientId : transaction.senderId
        
        return if let savedName = container.addressBookService.getName(for: address) {
            savedName
        } else if let knownName = container.accountsProvider.getKnownAccountName(for: address) {
            knownName
        }
//        else if let name = partner.name {
//
//        } Need to add here name which are saved in blockchain
        else {
            address
        }
    }
}

struct ChatListCellAvatar {
    enum AvatarPartnerType {
        case knownContact
        case unknownContact
    }
    
    let avatarImage: UIImage?
    let partnerPublicKey: String?
    let type: AvatarPartnerType
    
    init(
        avatarImage: UIImage? = nil,
        partnerPublicKey: String? = nil,
        type: AvatarPartnerType
    ) {
        self.avatarImage = avatarImage
        self.partnerPublicKey = partnerPublicKey
        self.type = type
    }
}

private struct PartnerAvatarMapper {
    // MARK: - Dependency
    private let container: ChatListProviderDependencyContainer
    
    init(container: ChatListProviderDependencyContainer) {
        self.container = container
    }
    
    @MainActor
    func getAvatar(transaction: Transaction) -> ChatListCellAvatar {
        if let avatar = container.accountsProvider.getKnownAccountAvatar(for: transaction.senderId) {
            return .init(
                avatarImage: UIImage.asset(named: avatar),
                type: .knownContact
            )
        } else {
            let isOutMessage = container.accountService.account?.address == transaction.senderId
            let publicKey: String? = isOutMessage ? transaction.recipientPublicKey : transaction.senderPublicKey
            return .init(
                partnerPublicKey: publicKey,
                type: .unknownContact
            )
        }
    }
}

private class LastMessageMapper {
    // MARK: - Dependency
    private let container: ChatListProviderDependencyContainer
    private lazy var sendTxMapper: SendTransactionMapper = .init(container: container)
    private lazy var messageTxMapper: ChatMessageTransactionMapper = .init(container: container)

    init(container: ChatListProviderDependencyContainer) {
        self.container = container
    }
    
    func getMessageFrom(transaction: Transaction) -> NSAttributedString? {
        let amount = transaction.amount
        
        return switch (transaction.type, amount) {
        case (.chatMessage, amount) where amount <= 0:
            messageTxText(transaction: transaction)
        case (.chatMessage, amount) where amount > 0:
            sendTxText(transaction: transaction)
        case (.send, _):
            sendTxText(transaction: transaction)
        default:
            nil
        }
    }
    
    private func messageTxText(transaction: Transaction) -> NSAttributedString? {
        messageTxMapper.mapMessageFrom(
            senderId: transaction.senderId,
            senderPublicKey: transaction.senderPublicKey,
            recipientPublicKey: transaction.recipientPublicKey,
            message: transaction.asset.chat?.message,
            nonce: transaction.asset.chat?.ownMessage
        )
    }
    
    private func sendTxText(transaction: Transaction) -> NSAttributedString? {
        sendTxMapper.mapMessageFrom(senderId: transaction.senderId, amount: transaction.amount)
    }
}

private struct SendTransactionMapper {
    // MARK: - Dependency
    private let container: ChatListProviderDependencyContainer
    
    init(
        container: ChatListProviderDependencyContainer
    ) {
        self.container = container
    }
    
    func mapMessageFrom(senderId: String, amount: Decimal) -> NSAttributedString? {
        let isOutMessage = container.accountService.account?.address == senderId
        
        guard let balance = amount as Decimal? else {
            return NSAttributedString(string: "")
        }
        
        guard let walletService = container.walletServiceCompose.getWallet(by: AdmWalletService.richMessageType)?.core as? AdmWalletService else {
            return nil
        }
        return NSAttributedString(string: walletService.shortDescription(isOutgoing: isOutMessage, balance: balance))
    }
}

private struct ChatMessageTransactionMapper {
    // MARK: - Dependency
    private let container: ChatListProviderDependencyContainer
    
    private let markdownParser: MarkdownParser = {
        let parser = MarkdownParser(
            font: UIFont.systemFont(ofSize: ChatTableViewCell.shortDescriptionTextSize),
            color: .adamant.primary,
            enabledElements: [
                .header,
                .list,
                .quote,
                .bold,
                .italic,
                .strikethrough,
                .automaticLink
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
        
        return parser
    }()
    
    init(
        container: ChatListProviderDependencyContainer
    ) {
        self.container = container
    }
    
    func mapMessageFrom(
        senderId: String,
        senderPublicKey: String,
        recipientPublicKey: String?,
        message: String?,
        nonce: String?
    ) -> NSAttributedString? {
        let isOutMessage = container.accountService.account?.address == senderId
        let senderPublicKey: String = switch isOutMessage {
        case true: recipientPublicKey ?? senderPublicKey
        case false: senderPublicKey
        }
        
        guard var message = container.adamantCore.decodeMessage(
            rawMessage: message ?? "",
            rawNonce: nonce ?? "",
            senderPublicKey: senderPublicKey,
            privateKey: container.accountService.keypair?.privateKey ?? ""
        ) else { return nil }
        message = MessageProcessHelper.process(message)
        
        if isOutMessage {
            message = "\(String.adamant.chatList.sentMessagePrefix)\(message)"
        }
        
        var attributedMessage = markdownParser.parse(message).resolveLinkColor()
        attributedMessage = MessageProcessHelper.process(attributedText: attributedMessage)
        return attributedMessage
    }
}

struct NextGenChatroomCell {
    let avatar: ChatListCellAvatar
    let dateText: String?
    let accountText: String?
    let lastMessageText: NSAttributedString?
    let hasUnreadMessages: Bool
    
    init(
        avatar: ChatListCellAvatar,
        dateText: String?,
        accountText: String?,
        lastMessageText: NSAttributedString?,
        hasUnreadMessages: Bool
    ) {
        self.avatar = avatar
        self.dateText = dateText
        self.accountText = accountText
        self.lastMessageText = lastMessageText
        self.hasUnreadMessages = hasUnreadMessages
    }
}
