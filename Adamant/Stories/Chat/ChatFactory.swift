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
    let router: Router
    
    func makeViewController() -> UIViewController {
        let viewModel = makeViewModel()
        let managers = makeManagers(viewModel: viewModel)
        
        let viewController = ChatViewController(
            viewModel: viewModel,
            storedObjects: managers.asArray,
            sendTransaction: makeSendTransactionAction(viewModel: viewModel)
        )
        
        viewController.setupManagers(managers)
        return viewController
    }
}

private extension ChatFactory {
    struct Managers {
        let dataSource: MessagesDataSource
        let layout: MessagesLayoutDelegate
        let display: MessagesDisplayDelegate
        let inputBar: InputBarAccessoryViewDelegate
        
        var asArray: [AnyObject] {
            [dataSource, layout, display, inputBar]
        }
    }
    
    func makeViewModel() -> ChatViewModel {
        let richMessageProviders: Dictionary = Dictionary(
            uniqueKeysWithValues: accountService
                .wallets
                .compactMap { $0 as? RichMessageProvider }
                .map { ($0.dynamicRichMessageType, $0) }
        )
        
        return .init(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            dialogService: dialogService,
            transfersProvider: transferProvider,
            chatMessageFactory: .init(richMessageProviders: richMessageProviders),
            addressBookService: addressBookService,
            richMessageProviders: richMessageProviders
        )
    }
    
    func makeManagers(viewModel: ChatViewModel) -> Managers {
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
    func setupManagers(_ managers: ChatFactory.Managers) {
        messagesCollectionView.messagesDataSource = managers.dataSource
        messagesCollectionView.messagesLayoutDelegate = managers.layout
        messagesCollectionView.messagesDisplayDelegate = managers.display
        messageInputBar.delegate = managers.inputBar
    }
}
