//
//  ChatFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import MessageKit
import Combine

struct ChatFactory {
    let chatsProvider: ChatsProvider
    let dialogService: DialogService
    let transferProvider: TransfersProvider
    let accountService: AccountService
    let router: Router
    
    func makeViewController() -> UIViewController {
        let viewModel = makeViewModel()
        
        return ChatViewController(
            viewModel: viewModel,
            delegates: .init(
                dataSource: ChatDataSource(viewModel: viewModel),
                inputBarDelegate: ChatInputBarDelegate(sendMessageAction: viewModel.sendMessage),
                layoutDelegate: ChatLayoutDelegate(viewModel: viewModel),
                displayDelegate: ChatDisplayDelegate(viewModel: viewModel)
            ),
            sendTransaction: makeSendTransactionAction(viewModel: viewModel)
        )
    }
}

private extension ChatFactory {
    func makeViewModel() -> ChatViewModel {
        let richMessageProviders = accountService
            .wallets
            .compactMap { $0 as? RichMessageProvider }
        
        return .init(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            dialogService: dialogService,
            transfersProvider: transferProvider,
            chatMessageFactory: .init(richMessageProviders: .init(
                uniqueKeysWithValues: richMessageProviders.map { ($0.dynamicRichMessageType, $0) }
            ))
        )
    }
    
    func makeSendTransactionAction(viewModel: ChatViewModel) -> ChatViewController.SendTransaction {
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
