//
//  ChatMediaCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import MessageKit
import Combine

final class ChatMediaCell: MessageContentCell, ChatModelView {
    private let containerMediaView = ChatMediaContainerView()
    private let cellContainerView = UIView()
    private lazy var swipeWrapper = ChatSwipeWrapper(cellContainerView)
    
    var subscription: AnyCancellable?
    
    var model: ChatMediaContainerView.Model = .default {
        didSet {
            swipeWrapper.model = .init(id: model.id, state: model.swipeState)
            containerMediaView.model = model
        }
    }
    
    var actionHandler: (ChatAction) -> Void {
        get { containerMediaView.actionHandler }
        set { containerMediaView.actionHandler = newValue }
    }
    
    var chatMessagesListViewModel: ChatMessagesListViewModel? {
        get { containerMediaView.chatMessagesListViewModel }
        set { containerMediaView.chatMessagesListViewModel = newValue }
    }
    
    override var isSelected: Bool {
        didSet {
            containerMediaView.isSelected = isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
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
        
        containerMediaView.snp.remakeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(messageContainerView.frame.origin.y)
            make.height.equalTo(messageContainerView.frame.height)
        }
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
            containerMediaView
        )
    }
}

private extension ChatMediaCell {
    func configure() {
        contentView.addSubview(swipeWrapper)
        swipeWrapper.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
