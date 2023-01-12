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
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func avatarSize(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGSize? { .zero }
    
    func cellTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat {
        viewModel.isNeedToDisplayDateHeader(sentDate: message.sentDate, index: indexPath.section)
            ? labelHeight
            : .zero
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat {
        message.fullModel.status == .failed
            ? labelHeight
            : .zero
    }
    
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
        in messagesCollectionView: MessagesCollectionView
    ) -> CellSizeCalculator {
        ChatTransactionCellSizeCalculator(
            layout: messagesCollectionView.messagesCollectionViewFlowLayout,
            getCurrentSender: { [sender = viewModel.sender] in sender.value },
            getMessages: { [messages = viewModel.messages] in messages.value }
        )
    }
    
    func headerViewSize(
        for section: Int,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        section == .zero && viewModel.loadingStatus.value == .onTop
            ? SpinnerView.size
            : .zero
    }
}

private extension ChatLayoutDelegate {
    func textAlignment(for message: MessageType) -> NSTextAlignment {
        message.sender.senderId == viewModel.sender.value.senderId
            ? .right
            : .left
    }
}

private let labelHeight: CGFloat = 16
private let labelSideInset: CGFloat = 12

private let topBottomLabelInsets = UIEdgeInsets(
    top: 2,
    left: labelSideInset,
    bottom: .zero,
    right: labelSideInset
)
