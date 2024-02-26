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
import Swinject
import FilesStorageKit

@MainActor
struct ChatFactory {
    let chatCacheService = ChatCacheService()
    let chatsProvider: ChatsProvider
    let dialogService: DialogService
    let transferProvider: TransfersProvider
    let accountService: AccountService
    let accountProvider: AccountsProvider
    let richTransactionStatusService: TransactionStatusService
    let addressBookService: AddressBookService
    let visibleWalletService: VisibleWalletsService
    let avatarService: AvatarService
    let emojiService: EmojiService
    let walletServiceCompose: WalletServiceCompose
    
    nonisolated init(assembler: Assembler) {
        chatsProvider = assembler.resolve(ChatsProvider.self)!
        dialogService = assembler.resolve(DialogService.self)!
        transferProvider = assembler.resolve(TransfersProvider.self)!
        accountService = assembler.resolve(AccountService.self)!
        accountProvider = assembler.resolve(AccountsProvider.self)!
        richTransactionStatusService = assembler.resolve(TransactionStatusService.self)!
        addressBookService = assembler.resolve(AddressBookService.self)!
        visibleWalletService = assembler.resolve(VisibleWalletsService.self)!
        avatarService = assembler.resolve(AvatarService.self)!
        emojiService = assembler.resolve(EmojiService.self)!
        walletServiceCompose = assembler.resolve(WalletServiceCompose.self)!
    }
    
    func makeViewController(screensFactory: ScreensFactory) -> ChatViewController {
        let viewModel = makeViewModel()
        let delegates = makeDelegates(viewModel: viewModel)
        let dialogManager = ChatDialogManager(
            viewModel: viewModel,
            dialogService: dialogService,
            emojiService: emojiService
        )
        
        let wallets = walletServiceCompose.getWallets()
        
        let walletService = wallets.first { wallet in
            return wallet.core is AdmWalletService
        }
        
        let viewController = ChatViewController(
            viewModel: viewModel,
            walletServiceCompose: walletServiceCompose,
            storedObjects: delegates.asArray + [dialogManager],
            admWalletService: walletService,
            screensFactory: screensFactory,
            sendTransaction: makeSendTransactionAction(
                viewModel: viewModel,
                screensFactory: screensFactory
            )
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
    
    func makeViewModel() -> ChatViewModel {
        .init(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            transfersProvider: transferProvider,
            chatMessagesListFactory: .init(chatMessageFactory: .init(
                walletServiceCompose: walletServiceCompose
            )),
            addressBookService: addressBookService,
            visibleWalletService: visibleWalletService,
            accountService: accountService,
            accountProvider: accountProvider,
            richTransactionStatusService: richTransactionStatusService,
            chatCacheService: chatCacheService,
            walletServiceCompose: walletServiceCompose,
            avatarService: avatarService,
            chatMessagesListViewModel: .init(
                avatarService: avatarService,
                emojiService: emojiService
            ),
            emojiService: emojiService
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
        viewModel: ChatViewModel,
        screensFactory: ScreensFactory
    ) -> ChatViewController.SendTransaction {
        { [screensFactory, viewModel] parentVC, messageId in
            guard let vc = screensFactory.makeComplexTransfer() as? ComplexTransferViewController
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
