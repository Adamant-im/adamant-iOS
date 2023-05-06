//
//  ChatTransactionCellSizeCalculator.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

final class ChatTransactionCellSizeCalculator: CellSizeCalculator {
    private let measuredView = ChatTransactionContainerView()
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
        guard
            case let .transaction(model) = getMessages()[indexPath.section].fullModel.content
        else { return .zero }
        
        return .init(
            width: messagesFlowLayout.itemWidth,
            height: model.value.height(for: messagesFlowLayout.itemWidth)
        )
    }
}
