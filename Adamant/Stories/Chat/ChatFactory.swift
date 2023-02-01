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

struct ChatFactory {
    let chatsProvider: ChatsProvider
    let dialogService: DialogService
    let transferProvider: TransfersProvider
    let accountService: AccountService
    let addressBookService: AddressBookService
    let visibleWalletService: VisibleWalletsService
    let router: Router
    
    func makeViewController() -> UIViewController {
        let richMessageProviders = makeRichMessageProviders()
        let viewModel = makeViewModel(richMessageProviders: richMessageProviders)
        let delegates = makeDelegates(viewModel: viewModel)
        let dialogManager = ChatDialogManager(viewModel: viewModel, dialogService: dialogService)
        
        let viewController = ChatViewController(
            viewModel: viewModel,
            richMessageProviders: richMessageProviders,
            storedObjects: delegates.asArray + [dialogManager],
            sendTransaction: makeSendTransactionAction(viewModel: viewModel)
        )
        
        viewController.setupDelegates(delegates)
        return viewController
    }
}

private extension ChatFactory {
    struct Delegates {
        let dataSource: MessagesDataSource
        let layout: MessagesLayoutDelegate
        let display: MessagesDisplayDelegate
        let inputBar: InputBarAccessoryViewDelegate
        
        var asArray: [AnyObject] {
            [dataSource, layout, display, inputBar]
        }
    }
    
    func makeViewModel(richMessageProviders: [String: RichMessageProvider]) -> ChatViewModel {
        .init(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            transfersProvider: transferProvider,
            chatMessageFactory: .init(richMessageProviders: richMessageProviders),
            addressBookService: addressBookService,
            visibleWalletService: visibleWalletService,
            accountService: accountService,
            richMessageProviders: richMessageProviders
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
            inputBar: ChatInputBarManager(sendMessageAction: viewModel.sendMessage)
        )
    }
    
    func makeSendTransactionAction(
        viewModel: ChatViewModel
    ) -> ChatViewController.SendTransaction {
        { [router, viewModel] parentVC in
            guard let vc = router.get(scene: AdamantScene.Chats.complexTransfer) as? ComplexTransferViewController
            else { return }
            
            vc.partner = viewModel.chatroom?.partner
            vc.transferDelegate = parentVC
            
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
        messageInputBar.delegate = delegates.inputBar
    }
}
