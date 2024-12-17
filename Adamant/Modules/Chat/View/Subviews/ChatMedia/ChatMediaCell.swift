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
    let containerMediaView = ChatSwipeWrapper(ChatMediaContainerView())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        containerMediaView.wrappedView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            containerMediaView.wrappedView.isSelected = isSelected
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
        
        containerMediaView.snp.remakeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(messageContainerView.frame.origin.y)
            make.height.equalTo(messageContainerView.frame.height)
        }
    }
}

private extension ChatMediaCell {
    func configure() {
        contentView.addSubview(containerMediaView)
        containerMediaView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
    }
}
