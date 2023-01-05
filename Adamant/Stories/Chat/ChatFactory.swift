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
    
    func makeViewController() -> UIViewController {
        let viewModel = ChatViewModel(
            chatsProvider: chatsProvider,
            markdownParser: .init(font: UIFont.systemFont(ofSize: UIFont.systemFontSize)),
            dialogService: dialogService,
            transfersProvider: transferProvider
        )
        
        return ChatViewController(
            viewModel: viewModel,
            delegates: .init(
                dataSource: ChatDataSource(viewModel: viewModel),
                inputBarDelegate: ChatInputBarDelegate(sendMessageAction: viewModel.sendMessage),
                layoutDelegate: ChatLayoutDelegate(viewModel: viewModel),
                displayDelegate: ChatDisplayDelegate(viewModel: viewModel)
            )
        )
    }
}
