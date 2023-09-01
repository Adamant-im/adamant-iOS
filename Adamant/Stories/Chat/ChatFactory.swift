//
//  ChatFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Combine

@MainActor
struct ChatFactory {
    let chatCacheService = ChatCacheService()
    let chatsProvider: ChatsProvider
    let dialogService: DialogService
    let transferProvider: TransfersProvider
    let accountService: AccountService
    let accountProvider: AccountsProvider
    let richTransactionStatusService: RichTransactionStatusService
    let addressBookService: AddressBookService
    let visibleWalletService: VisibleWalletsService
    let avatarService: AvatarService
    let emojiService: EmojiService
    let router: Router
    
    func makeViewController() -> UIViewController {
        let richMessageProviders = makeRichMessageProviders()
        let viewModel = makeViewModel(richMessageProviders: richMessageProviders)
        let delegates = makeDelegates(viewModel: viewModel)
        let dialogManager = ChatDialogManager(viewModel: viewModel, dialogService: dialogService)
        
        let admService = accountService.wallets.first { wallet in
            return wallet is AdmWalletService
        } as? AdmWalletService
        
        let viewController = ChatViewController(
            viewModel: viewModel,
            richMessageProviders: richMessageProviders,
            storedObjects: delegates.asArray + [dialogManager],
            sendTransaction: makeSendTransactionAction(viewModel: viewModel),
            admService: admService
        )
        
        viewController.setupDelegates(delegates)
        delegates.cell.setupDelegate(
            collection: viewController.messagesCollectionView,
            dataSource: delegates.dataSource
        )
        return viewController
    }
}

private extension ChatFactory {
    struct Delegates {
        let dataSource: MessagesDataSource
        let layout: MessagesLayoutDelegate
        let display: MessagesDisplayDelegate
        let inputBar: InputBarAccessoryViewDelegate
        let cell: ChatCellManager
        
        var asArray: [AnyObject] {
            [dataSource, layout, display, inputBar, cell]
        }
    }
    
    func makeViewModel(richMessageProviders: [String: RichMessageProvider]) -> ChatViewModel {
        .init(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            transfersProvider: transferProvider,
            chatMessagesListFactory: .init(chatMessageFactory: .init(
                richMessageProviders: richMessageProviders
            )),
            addressBookService: addressBookService,
            visibleWalletService: visibleWalletService,
            accountService: accountService,
            accountProvider: accountProvider,
            richTransactionStatusService: richTransactionStatusService,
            chatCacheService: chatCacheService,
            richMessageProviders: richMessageProviders,
            avatarService: avatarService,
            chatMessagesListViewModel: .init(
                avatarService: avatarService,
                emojiService: emojiService
            )
        )
    }
    
    func makeRichMessageProviders() -> [String: RichMessageProvider] {
        .init(
            uniqueKeysWithValues: accountService
                .wallets
                .compactMap { $0 as? RichMessageProvider }
                .map { ($0.dynamicRichMessageType, $0) }
        )
    }
    
    func makeDelegates(viewModel: ChatViewModel) -> Delegates {
        .init(
            dataSource: ChatDataSourceManager(viewModel: viewModel),
            layout: ChatLayoutManager(viewModel: viewModel),
            display: ChatDisplayManager(viewModel: viewModel),
            inputBar: ChatInputBarManager(viewModel: viewModel),
            cell: ChatCellManager(viewModel: viewModel)
        )
    }
    
    func makeSendTransactionAction(
        viewModel: ChatViewModel
    ) -> ChatViewController.SendTransaction {
        { [router, viewModel] parentVC, messageId in
            guard let vc = router.get(scene: AdamantScene.Chats.complexTransfer) as? ComplexTransferViewController
            else { return }
            
            vc.partner = viewModel.chatroom?.partner
            vc.transferDelegate = parentVC
            vc.replyToMessageId = messageId
            
            let navigator = UINavigationController(rootViewController: vc)
            navigator.modalPresentationStyle = .overFullScreen
            parentVC.present(navigator, animated: true, completion: nil)
        }
    }
}

private extension ChatViewController {
    func setupDelegates(_ delegates: ChatFactory.Delegates) {
        messagesCollectionView.messagesDataSource = delegates.dataSource
        messagesCollectionView.messagesLayoutDelegate = delegates.layout
        messagesCollectionView.messagesDisplayDelegate = delegates.display
        messagesCollectionView.messageCellDelegate = delegates.cell
        messageInputBar.delegate = delegates.inputBar
    }
}

private extension ChatCellManager {
    func setupDelegate(collection: MessagesCollectionView, dataSource: MessagesDataSource) {
        getMessageId = { [weak collection, weak dataSource] cell in
            guard
                let collection = collection,
                let indexPath = collection.indexPath(for: cell),
                let message = dataSource?.messageForItem(at: indexPath, in: collection)
            else { return nil }
            
            return message.messageId
        }
    }
}
