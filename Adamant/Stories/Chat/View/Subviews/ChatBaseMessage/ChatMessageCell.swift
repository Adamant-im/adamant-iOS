//
//  ChatBaseTextMessageView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import MessageKit
import Combine

final class ChatMessageCell: TextMessageCell, ChatModelView {    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: contentView, messagePadding: 8)
        return view
    }()
    
    // MARK: - Properties
    
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            swipeView.update(model)
            
            let isSelected = oldValue.animationId != model.animationId
            && !model.animationId.isEmpty
            && oldValue.id == model.id
            && !model.id.isEmpty
            && !oldValue.id.isEmpty
            
            if isSelected {
                messageContainerView.startBlinkAnimation()
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                messageContainerView.startBlinkAnimation()
            }
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    var subscription: AnyCancellable?
    
    private var containerView: UIView = UIView()
    
    // MARK: - Methods
    
    override func setupSubviews() {
        super.setupSubviews()
        
        contentView.addSubview(swipeView)
        swipeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.top.equalToSuperview()
        }
        
        swipeView.action = { [weak self] message in
            self?.actionHandler(.reply(message: message))
        }
        
        swipeView.swipeStateAction = { [weak self] state in
            self?.actionHandler(.swipeState(state: state))
        }
        
        configureMenu()
    }
    
    func configureMenu() {
        messageContainerView.removeFromSuperview()
        contentView.addSubview(containerView)
        
        let interaction = UIContextMenuInteraction(delegate: self)
        containerView.addSubview(messageContainerView)
        
        containerView.addInteraction(interaction)
        messageContainerView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
    
    override func layoutMessageContainerView(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
        var origin: CGPoint = .zero

        switch attributes.avatarPosition.vertical {
        case .messageBottom:
          origin.y = attributes.size.height
            - attributes.messageContainerPadding.bottom
            - attributes.cellBottomLabelSize.height
            - attributes.messageBottomLabelSize.height
            - attributes.messageContainerSize.height
            - attributes.messageContainerPadding.top
        case .messageCenter:
          if attributes.avatarSize.height > attributes.messageContainerSize.height {
            let messageHeight = attributes.messageContainerSize.height
              + attributes.messageContainerPadding.top
              + attributes.messageContainerPadding.bottom
            origin.y = (attributes.size.height / 2) - (messageHeight / 2)
          } else {
            fallthrough
          }
        default:
          if attributes.accessoryViewSize.height > attributes.messageContainerSize.height {
            let messageHeight = attributes.messageContainerSize.height
              + attributes.messageContainerPadding.top
              + attributes.messageContainerPadding.bottom
            origin.y = (attributes.size.height / 2) - (messageHeight / 2)
          } else {
            origin.y = attributes.cellTopLabelSize.height
              + attributes.messageTopLabelSize.height
              + attributes.messageContainerPadding.top
          }
        }

        let avatarPadding = attributes.avatarLeadingTrailingPadding
        switch attributes.avatarPosition.horizontal {
        case .cellLeading:
          origin.x = attributes.avatarSize.width
            + attributes.messageContainerPadding.left
            + avatarPadding
        case .cellTrailing:
          origin.x = attributes.frame.width
            - attributes.avatarSize.width
            - attributes.messageContainerSize.width
            - attributes.messageContainerPadding.right
            - avatarPadding
        case .natural:
          break
        }

        containerView.frame = CGRect(
            origin: origin,
            size: attributes.messageContainerSize
        )
        containerView.layoutIfNeeded()
        messageContainerView.layoutIfNeeded()
    }
}

extension ChatMessageCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            guard let self = self else { return nil }
            return self.makeContextMenu()
        })
    }
    
    func makeContextMenu() -> UIMenu {
        let remove = UIAction(
            title: .adamantLocalized.chat.remove,
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { _ in
            self.actionHandler(.remove(id: self.model.id))
        }
        
        let report = UIAction(
            title: .adamantLocalized.chat.report,
            image: UIImage(systemName: "exclamationmark.bubble")
        ) { _ in
            self.actionHandler(.report(id: self.model.id))
        }
        
        let reply = UIAction(
            title: .adamantLocalized.chat.reply,
            image: UIImage(systemName: "arrowshape.turn.up.left")
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { self.actionHandler(.reply(message: self.model)) }
        }
        
        let copy = UIAction(
            title: .adamantLocalized.chat.copy,
            image: UIImage(systemName: "doc.on.doc")
        ) { [weak self] _ in
            guard let self = self else { return }
            self.actionHandler(.copy(text: self.model.text.string))
        }
        
        return UIMenu(children: [reply, copy, report, remove])
    }
}
