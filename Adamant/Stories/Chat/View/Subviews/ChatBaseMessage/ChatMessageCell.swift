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
import SwiftUI
import AdvancedContextMenuKit

final class ChatMessageCell: TextMessageCell, ChatModelView {
    // MARK: Dependencies
    
    var chatMessagesListViewModel: ChatMessagesListViewModel?
    
    // MARK: Proprieties
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: contentView, xPadding: 8)
        return view
    }()
    
    private lazy var reactionsContanerView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ownReactionLabel, opponentReactionLabel])
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.spacing = 6
        return stack
    }()
    
    private lazy var ownReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.address)
        label.backgroundColor = .adamant.pickedReactionBackground
        label.layer.cornerRadius = ownReactionSize.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.frame.size = ownReactionSize
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapReactionAction)
        )
        
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var opponentReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.opponentAddress)
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.backgroundColor = .adamant.pickedReactionBackground
        label.layer.cornerRadius = opponentReactionSize.height / 2
        label.frame.size = opponentReactionSize
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapReactionAction)
        )
        
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var chatMenuManager: ChatMenuManager = {
        let manager = ChatMenuManager(
            menu: makeContextMenu(),
            emojiService: chatMessagesListViewModel?.emojiService
        )
        manager.delegate = self
        return manager
    }()
    
    private lazy var contextMenu = AdvancedContextMenuManager(delegate: chatMenuManager)
    
    // MARK: - Properties
    
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            chatMenuManager.selectedEmoji = getReaction(for: model.address)
            chatMenuManager.emojiService = chatMessagesListViewModel?.emojiService
            
            reactionsContanerView.isHidden = model.reactions == nil
            ownReactionLabel.isHidden = getReaction(for: model.address) == nil
            opponentReactionLabel.isHidden = getReaction(for: model.opponentAddress) == nil
            updateOwnReaction()
            updateOpponentReaction()
            layoutReactionLabel()
        }
    }
    
    var reactionsContanerViewWidth: CGFloat {
        if getReaction(for: model.address) == nil &&
            getReaction(for: model.opponentAddress) == nil {
            return .zero
        }
        
        if getReaction(for: model.address) != nil &&
            getReaction(for: model.opponentAddress) != nil {
            return ownReactionSize.width + opponentReactionSize.width + 6
        }
        
        if getReaction(for: model.address) != nil {
            return ownReactionSize.width
        }
        
        if getReaction(for: model.opponentAddress) != nil {
            return opponentReactionSize.width
        }
        
        return .zero
    }
    
    override var isSelected: Bool {
        didSet {
            messageContainerView.animateIsSelected(
                isSelected,
                originalColor: model.backgroundColor.uiColor
            )
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    var subscription: AnyCancellable?
    
    private var containerView: UIView = UIView()
    private let ownReactionSize = CGSize(width: 40, height: 27)
    private let opponentReactionSize = CGSize(width: 55, height: 27)
    private let opponentReactionImageSize = CGSize(width: 10, height: 12)
    private var layoutAttributes: MessagesCollectionViewLayoutAttributes?
    
    // MARK: - Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ownReactionLabel.text = nil
        opponentReactionLabel.attributedText = nil
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        contentView.addSubview(swipeView)
        swipeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.top.equalToSuperview()
        }
        
        swipeView.didSwipeAction = { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.reply(message: self.model))
        }
        
        swipeView.swipeStateAction = { [weak self] state in
            self?.actionHandler(.swipeState(state: state))
        }
        
        configureMenu()
        
        contentView.addSubview(reactionsContanerView)
    }
    
    func configureMenu() {
        containerView.layer.cornerRadius = 10
        
        messageContainerView.removeFromSuperview()
        contentView.addSubview(containerView)
        
        containerView.addSubview(messageContainerView)
        
        contextMenu.setup(for: containerView)
    }
    
    func updateOwnReaction() {
        ownReactionLabel.text = getReaction(for: model.address)
        ownReactionLabel.backgroundColor = model.backgroundColor.uiColor.mixin(
            infusion: .lightGray,
            alpha: 0.15
        )
    }
    
    func updateOpponentReaction() {
        guard let reaction = getReaction(for: model.opponentAddress) else {
            opponentReactionLabel.attributedText = nil
            opponentReactionLabel.text = nil
            return
        }
        
        let fullString = NSMutableAttributedString(string: reaction)
        
        if let image = chatMessagesListViewModel?.avatarService.avatar(
            for: model.opponentAddress,
            size: opponentReactionImageSize.width
        ) {
            let replyImageAttachment = NSTextAttachment()
            replyImageAttachment.image = image
            replyImageAttachment.bounds = .init(
                origin: .init(x: .zero, y: -3),
                size: opponentReactionImageSize
            )
            
            let imageString = NSAttributedString(attachment: replyImageAttachment)
            fullString.append(NSAttributedString(string: " "))
            fullString.append(imageString)
        }
        
        opponentReactionLabel.attributedText = fullString
        opponentReactionLabel.backgroundColor = model.backgroundColor.uiColor.mixin(
            infusion: .lightGray,
            alpha: 0.15
        )
    }
    
    func getReaction(for address: String) -> String? {
        model.reactions?.first(
            where: { $0.sender == address }
        )?.reaction
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes
        else { return }
        
        self.layoutAttributes = attributes
    }
    
    /// Positions the message bubble's top label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    override func layoutMessageTopLabel(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
      messageTopLabel.textAlignment = attributes.messageTopLabelAlignment.textAlignment
      messageTopLabel.textInsets = attributes.messageTopLabelAlignment.textInsets

      let y = containerView.frame.minY - attributes.messageContainerPadding.top - attributes.messageTopLabelSize.height
      let origin = CGPoint(x: 0, y: y)

      messageTopLabel.frame = CGRect(origin: origin, size: attributes.messageTopLabelSize)
    }

    /// Positions the message bubble's bottom label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    override func layoutMessageBottomLabel(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
      messageBottomLabel.textAlignment = attributes.messageBottomLabelAlignment.textAlignment
      messageBottomLabel.textInsets = attributes.messageBottomLabelAlignment.textInsets

      let y = containerView.frame.maxY + attributes.messageContainerPadding.bottom
      let origin = CGPoint(x: 0, y: y)

      messageBottomLabel.frame = CGRect(origin: origin, size: attributes.messageBottomLabelSize)
    }
    
    ///  Positions the message bubble's time label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    override func layoutTimeLabelView(
        with attributes: MessagesCollectionViewLayoutAttributes
    ) {
        let paddingLeft: CGFloat = 10
        let origin = CGPoint(
          x: UIScreen.main.bounds.width + paddingLeft,
          y: containerView.frame.minY
          + containerView.frame.height
          * 0.5
          - messageTimestampLabel.font.ascender * 0.5
        )
        
        let size = CGSize(
            width: attributes.messageTimeLabelSize.width,
            height: attributes.messageTimeLabelSize.height
        )
        
        messageTimestampLabel.frame = CGRect(origin: origin, size: size)
    }
    
    /// Positions the cell's `MessageContainerView`.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
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
        messageContainerView.frame = CGRect(
            origin: .zero,
            size: attributes.messageContainerSize
        )
        containerView.layoutIfNeeded()
        messageContainerView.layoutIfNeeded()
        layoutReactionLabel()
    }
    
    func layoutReactionLabel() {
        let additionalWidth: CGFloat = model.isFromCurrentSender
        ? .zero
        : containerView.frame.width
        
        var x = containerView.frame.origin.x
        + additionalWidth
        - reactionsContanerViewWidth / 2
        
        let minSpace = model.isFromCurrentSender
        ? minReactionsContanerHorizontalSpace + reactionsContanerViewWidth
        : minReactionsContanerHorizontalSpace
        
        x = model.isFromCurrentSender
        ? contentView.bounds.width - x > minSpace ? x : contentView.bounds.width - minSpace
        : x > minSpace ? x : minSpace
        
        reactionsContanerView.frame = CGRect(
            origin: .init(
                x: x,
                y: containerView.frame.origin.y
                + containerView.frame.height
                - reactionsContanerVerticalSpace
            ),
            size: .init(width: reactionsContanerViewWidth, height: ownReactionSize.height)
        )
        reactionsContanerView.layoutIfNeeded()
    }
    
    override func configure(
        with message: MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView
    ) {
        super.configure(
            with: message,
            at: indexPath,
            and: messagesCollectionView
        )
        
        updateOwnReaction()
        updateOpponentReaction()
    }
}

extension ChatMessageCell {
    func makeContextMenu() -> AMenuSection {
        let remove = AMenuItem.action(
            title: .adamant.chat.remove,
            systemImageName: "trash",
            style: .destructive
        ) { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.remove(id: self.model.id))
        }
        
        let report = AMenuItem.action(
            title: .adamant.chat.report,
            systemImageName: "exclamationmark.bubble"
        ) { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.report(id: self.model.id))
        }
        
        let reply = AMenuItem.action(
            title: .adamant.chat.reply,
            systemImageName: "arrowshape.turn.up.left"
        ) { [weak self] in
            guard let self = self else { return }
            Task { self.actionHandler(.reply(message: self.model)) }
        }
        
        let copy = AMenuItem.action(
            title: .adamant.chat.copy,
            systemImageName: "doc.on.doc"
        ) { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.copy(text: self.model.text.string))
        }
        
        return AMenuSection([reply, copy, report, remove])
    }
    
    @objc func tapReactionAction() {
        contextMenu.presentMenu(
            for: containerView,
            copyView: copy(
                with: model,
                attributes: layoutAttributes,
                urlAttributes: messageLabel.urlAttributes,
                enabledDetectors: messageLabel.enabledDetectors
            )?.containerView,
            with: makeContextMenu()
        )
    }
}

extension ChatMessageCell: ChatMenuManagerDelegate {
    func didReact(_ emoji: String) {
        Task {
            await contextMenu.dismiss()
            self.actionHandler(.react(id: self.model.id, emoji: emoji))
        }
    }
    
    func getContentView() -> UIView? {
        copy(
            with: model,
            attributes: layoutAttributes,
            urlAttributes: messageLabel.urlAttributes,
            enabledDetectors: messageLabel.enabledDetectors
        )?.containerView
    }
}

extension ChatMessageCell {
    func copy(
        with model: Model,
        attributes: MessagesCollectionViewLayoutAttributes?,
        urlAttributes: [NSAttributedString.Key : Any],
        enabledDetectors: [DetectorType]
    ) -> ChatMessageCell? {
        guard let attributes = attributes else { return nil }
        
        let cell = ChatMessageCell(frame: frame)
        cell.apply(attributes)
        
        cell.messageContainerView.backgroundColor = model.backgroundColor.uiColor
        cell.messageLabel.configure {
            cell.messageLabel.enabledDetectors = enabledDetectors
            cell.messageLabel.setAttributes(urlAttributes, detector: .url)
            cell.messageLabel.attributedText = model.text
        }
        cell.messageContainerView.style = .bubbleTail(
            model.isFromCurrentSender
                ? .bottomRight
                : .bottomLeft,
            .curved
        )
        return cell
    }
}

private let reactionsContanerVerticalSpace: CGFloat = 10
private let minReactionsContanerHorizontalSpace: CGFloat = 60
