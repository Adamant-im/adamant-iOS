//
//  ChatTransactionCell.swift
//  Adamant
//
//  Created by Andrey Golubenko on 20.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import MessageKit
import Combine

final class ChatTransactionCell: MessageContentCell, ChatModelView {
    private let transactionView = ChatTransactionContainerView()
    private let cellContainerView = UIView()
    private lazy var swipeWrapper = ChatSwipeWrapper(cellContainerView)
    
    var subscription: AnyCancellable?
    
    var model: ChatTransactionContainerView.Model = .default {
        didSet {
            swipeWrapper.model = .init(id: model.id, state: model.swipeState)
            transactionView.model = model
        }
    }
    
    var actionHandler: (ChatAction) -> Void {
        get { transactionView.actionHandler }
        set { transactionView.actionHandler = newValue }
    }
    
    var chatMessagesListViewModel: ChatMessagesListViewModel? {
        get { transactionView.chatMessagesListViewModel }
        set { transactionView.chatMessagesListViewModel = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        transactionView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            transactionView.isSelected = isSelected
        }
    }
    
    override func configure(
        with message: MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView
    ) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        messageContainerView.style = .none
        messageContainerView.backgroundColor = .clear
    }
    
    override func layoutMessageContainerView(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
        super.layoutMessageContainerView(with: attributes)
        transactionView.frame = messageContainerView.frame
        transactionView.layoutIfNeeded()
    }
    
    override func setupSubviews() {
        cellContainerView.addSubviews(
            accessoryView,
            cellTopLabel,
            messageTopLabel,
            messageBottomLabel,
            cellBottomLabel,
            messageContainerView,
            avatarView,
            messageTimestampLabel,
            transactionView
        )
    }
}

private extension ChatTransactionCell {
    func configure() {
        contentView.addSubview(swipeWrapper)
        swipeWrapper.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
