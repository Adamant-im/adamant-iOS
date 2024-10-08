//
//  ChatLayoutManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

@preconcurrency import MessageKit
import UIKit
import Combine

@MainActor
final class ChatLayoutManager: MessagesLayoutDelegate {
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    nonisolated func avatarSize(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGSize? { .zero }
    
    nonisolated func cellTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat {
        message.fullModel.dateHeaderIsHidden
            ? .zero
            : labelHeight
    }
    
    nonisolated func messageTopLabelHeight(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat {
        message.fullModel.status == .failed
            ? labelHeight
            : .zero
    }
    
    nonisolated func messageBottomLabelHeight(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> CGFloat {
        message.fullModel.bottomString == nil
            ? .zero
            : labelHeight
    }
    
    nonisolated func messageTopLabelAlignment(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> LabelAlignment? {
        MainActor.assumeIsolated {
            .init(
                textAlignment: textAlignment(for: message),
                textInsets: topBottomLabelInsets
            )
        }
    }
    
    nonisolated func messageBottomLabelAlignment(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> LabelAlignment? {
        MainActor.assumeIsolated {
            .init(
                textAlignment: textAlignment(for: message),
                textInsets: topBottomLabelInsets
            )
        }
    }
    
    nonisolated func textCellSizeCalculator(
        for _: MessageType,
        at _: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CellSizeCalculator? {
        MainActor.assumeIsolated {
            FixedTextMessageSizeCalculator(
                layout: messagesCollectionView.messagesCollectionViewFlowLayout,
                getCurrentSender: { [sender = viewModel.sender] in sender },
                getMessages: { [messages = viewModel.messages] in messages }
            )
        }
    }
    
    nonisolated func customCellSizeCalculator(
        for _: MessageType,
        at _: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CellSizeCalculator {
        MainActor.assumeIsolated {
            FixedTextMessageSizeCalculator(
                layout: messagesCollectionView.messagesCollectionViewFlowLayout,
                getCurrentSender: { [sender = viewModel.sender] in sender },
                getMessages: { [messages = viewModel.messages] in messages }
            )
        }
    }
    
    nonisolated func headerViewSize(
        for section: Int,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        MainActor.assumeIsolated {
            viewModel.messages[section].topSpinnerOn
                ? SpinnerView.size
                : .zero
        }
    }
    
    nonisolated func attributedTextCellSizeCalculator(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CellSizeCalculator? {
        MainActor.assumeIsolated {
            FixedTextMessageSizeCalculator(
                layout: messagesCollectionView.messagesCollectionViewFlowLayout,
                getCurrentSender: { [sender = viewModel.sender] in sender },
                getMessages: { [messages = viewModel.messages] in messages }
            )
        }
    }
}

private extension ChatLayoutManager {
    func textAlignment(for message: MessageType) -> NSTextAlignment {
        message.sender.senderId == viewModel.sender.senderId
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
