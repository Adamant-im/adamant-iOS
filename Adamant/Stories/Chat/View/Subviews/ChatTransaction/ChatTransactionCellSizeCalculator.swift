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
        if case let .transaction(model) = getMessages()[indexPath.section].fullModel.content {
            return .init(
                width: messagesFlowLayout.itemWidth,
                height: model.height(for: messagesFlowLayout.itemWidth)
            )
        }
        
//        if case let .reply(model) = getMessages()[indexPath.section].fullModel.content {
//            return .init(
//                width: messagesFlowLayout.itemWidth,
//                height: model.height(for: messagesFlowLayout.itemWidth)
//            )
//        }
        
        if case let .message(model) = getMessages()[indexPath.section].fullModel.content {
            let newModel = ChatMessageCell.Model(id: "", text: model.string)
            return .init(
                width: messagesFlowLayout.itemWidth,
                height: newModel.height(for: messagesFlowLayout.itemWidth)
            )
        }
        
        return .zero
    }
}
