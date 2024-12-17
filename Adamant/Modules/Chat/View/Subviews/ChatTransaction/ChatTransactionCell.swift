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

final class ChatTransactionCell: MessageContentCell {
    let transactionView = ChatSwipeWrapper(ChatTransactionContainerView())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        transactionView.wrappedView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            transactionView.wrappedView.isSelected = isSelected
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
}

private extension ChatTransactionCell {
    func configure() {
        contentView.addSubview(transactionView)
        transactionView.frame = messageContainerView.frame
    }
}
