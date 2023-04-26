//
//  ChatCellSizeCalculator.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

final class ChatCellSizeCalculator: CellSizeCalculator {    
    private let getCurrentSender: () -> SenderType
    private let getMessages: () -> [ChatMessage]
    private let messagesFlowLayout: MessagesCollectionViewFlowLayout
    
    init(
        layout: MessagesCollectionViewFlowLayout,
        getCurrentSender: @escaping () -> SenderType,
        getMessages: @escaping () -> [ChatMessage]
    ) {
        self.getMessages = getMessages
        self.getCurrentSender = getCurrentSender
        self.messagesFlowLayout = layout
        super.init()
        self.layout = layout
    }
    
    override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        switch getMessages()[indexPath.section].fullModel.content {
        case let .message(model):
            return sizeForModel(indexPath: indexPath, model: model.value)
        case let .reply(model):
            return sizeForModel(indexPath: indexPath, model: model.value)
        case let .transaction(model):
            return sizeForModel(indexPath: indexPath, model: model.value)
        }
    }
}

private extension ChatCellSizeCalculator {
    func sizeForModel<Model: ChatReusableViewModelProtocol>(
        indexPath: IndexPath,
        model: Model
    ) -> CGSize {
        .init(
            width: messagesFlowLayout.itemWidth,
            height: model.height(
                for: messagesFlowLayout.itemWidth,
                indexPath: indexPath,
                calculator: .init(layout: messagesFlowLayout)
            )
        )
    }
}
