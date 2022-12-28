//
//  ChatLayoutDelegate.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

final class ChatLayoutDelegate: MessagesLayoutDelegate {
    private let currentSender: ObservableVariable<ChatViewModel.Sender>
    
    init(currentSender: ObservableVariable<ChatViewModel.Sender>) {
        self.currentSender = currentSender
    }
    
    func avatarSize(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGSize? { .zero }
    
    func cellTopLabelHeight(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat { labelHeight }
    
    func messageTopLabelHeight(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat { labelHeight }
    
    func messageBottomLabelHeight(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat { labelHeight }
    
    func messageTopLabelAlignment(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> LabelAlignment? {
        .init(
            textAlignment: textAlignment(for: message),
            textInsets: topBottomLabelInsets
        )
    }
    
    func messageBottomLabelAlignment(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> LabelAlignment? {
        .init(
            textAlignment: textAlignment(for: message),
            textInsets: topBottomLabelInsets
        )
    }
    
    func customCellSizeCalculator(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CellSizeCalculator {
        .init()
    }
}

private extension ChatLayoutDelegate {
    func textAlignment(for message: MessageType) -> NSTextAlignment {
        message.sender.senderId == currentSender.value.senderId
            ? .right
            : .left
    }
}

private let labelHeight: CGFloat = 16
private let labelSideInset: CGFloat = 12

private let topBottomLabelInsets = UIEdgeInsets(
    top: .zero,
    left: labelSideInset,
    bottom: .zero,
    right: labelSideInset
)
