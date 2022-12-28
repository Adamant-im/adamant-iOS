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
    
    func makeViewController() -> UIViewController {
        let viewModel = ChatViewModel(chatsProvider: chatsProvider)
        
        return ChatViewController(
            viewModel: viewModel,
            delegates: .init(
                dataSource: makeDataSource(viewModel: viewModel),
                inputBarDelegate: makeInputBarDelegate(),
                layoutDelegate: makeLayoutDelegate(viewModel: viewModel),
                displayDelegate: makeDisplayDelegate(viewModel: viewModel)
            )
        )
    }
}

private extension ChatFactory {
    func makeDataSource(viewModel: ChatViewModel) -> ChatDataSource {
        .init(viewModel: viewModel)
    }
    
    func makeInputBarDelegate() -> ChatInputBarDelegate {
        .init(sendMessageAction: { _ in })
    }
    
    func makeLayoutDelegate(viewModel: ChatViewModel) -> ChatLayoutDelegate {
        .init(currentSender: viewModel.sender)
    }
    
    func makeDisplayDelegate(viewModel: ChatViewModel) -> ChatDisplayDelegate {
        .init(currentSender: viewModel.sender)
    }
}
