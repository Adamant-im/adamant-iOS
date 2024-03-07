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

final class ChatMediaCell: MessageContentCell {
    let containerMediaView = ChatMediaContainerView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        containerMediaView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            messageContainerView.animateIsSelected(
                isSelected,
                originalColor: messageContainerView.backgroundColor
            )
        }
    }
    
    override func configure(
        with message: MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView
    ) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
    }
    
    override func layoutMessageContainerView(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
        super.layoutMessageContainerView(with: attributes)
        containerMediaView.frame = messageContainerView.frame
        containerMediaView.layoutIfNeeded()
    }
}

private extension ChatMediaCell {
    func configure() {
        contentView.addSubview(containerMediaView)
        containerMediaView.frame = messageContainerView.frame
    }
}
