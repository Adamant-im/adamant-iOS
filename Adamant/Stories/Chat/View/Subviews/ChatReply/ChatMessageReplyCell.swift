//
//  ChatMessageReplyCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import MessageKit
import SnapKit
import Combine
import AdvancedContextMenuKit
import SwiftUI
import ElegantEmojiPicker

final class ChatMessageReplyCell: MessageContentCell, ChatModelView {    
    /// The labels used to display the message's text.
    private var messageLabel = MessageLabel()
    private var replyMessageLabel = UILabel()
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: contentView, xPadding: 8)
        return view
    }()
    
    static let replyViewHeight: CGFloat = 25
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .adamant.active
        return view
    }()
    
    private lazy var replyView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray.withAlphaComponent(0.15)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        view.addSubview(colorView)
        view.addSubview(replyMessageLabel)
        
        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        replyMessageLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-5)
            $0.leading.equalTo(colorView.snp.trailing).offset(6)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(Self.replyViewHeight)
        }
        return view
    }()
    
    private var containerView: UIView = UIView()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyView, messageLabel])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
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
        label.backgroundColor = .adamant.active
        label.layer.cornerRadius = ownReactionSize.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.frame.size = ownReactionSize
        return label
    }()
    
    private lazy var opponentReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.opponentAddress)
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.backgroundColor = .adamant.codeBlock
        label.layer.cornerRadius = 15
        label.frame.size = opponentReactionSize
        return label
    }()
    
    private lazy var chatMenuManager: ChatMenuManager = {
        let manager = ChatMenuManager(
            menu: makeContextMenu(),
            menuAlignment: model.isFromCurrentSender
            ? Alignment.trailing
            : Alignment.leading
        )
        manager.delegate = self
        return manager
    }()
    
    // MARK: - Properties
    
    /// The `MessageCellDelegate` for the cell.
    override weak var delegate: MessageCellDelegate? {
        didSet {
            messageLabel.delegate = delegate
        }
    }
    
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            
            replyMessageLabel.attributedText = model.messageReply
            chatMenuManager.menuAlignment = model.isFromCurrentSender
            ? Alignment.trailing
            : Alignment.leading
            
            let leading = model.isFromCurrentSender ? smallHInset : longHInset
            let trailing = model.isFromCurrentSender ? longHInset : smallHInset
            verticalStack.snp.updateConstraints {
                $0.leading.equalToSuperview().inset(leading)
                $0.trailing.equalToSuperview().inset(trailing)
            }
            
            ownReactionLabel.text = getReaction(for: model.address)
            reactionsContanerView.isHidden = model.reactions == nil
            ownReactionLabel.isHidden = getReaction(for: model.address) == nil
            opponentReactionLabel.isHidden = getReaction(for: model.opponentAddress) == nil
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
    
    private var trailingReplyViewOffset: CGFloat = 4
    private let smallHInset: CGFloat = 8
    private let longHInset: CGFloat = 14
    private let ownReactionSize = CGSize(width: 40, height: 30)
    private let opponentReactionSize = CGSize(width: 50, height: 30)
    private lazy var contextMenu = AdvancedContextMenuManager(delegate: chatMenuManager)
    
    // MARK: - Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        messageLabel.text = nil
        replyMessageLabel.attributedText = nil
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
        
        messageContainerView.addSubview(verticalStack)
        messageLabel.numberOfLines = 0
        replyMessageLabel.numberOfLines = 1
        
        let leading = model.isFromCurrentSender ? smallHInset : longHInset
        let trailing = model.isFromCurrentSender ? longHInset : smallHInset
        verticalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().inset(leading)
            $0.trailing.equalToSuperview().inset(trailing)
        }
        
        configureMenu()
        
        contentView.addSubview(reactionsContanerView)
    }
    
    func configureMenu() {
        containerView.layer.cornerRadius = 10
        
        messageContainerView.removeFromSuperview()
        contentView.addSubview(containerView)
        
        contextMenu.setup(for: containerView)
        
        containerView.addSubview(messageContainerView)
    }
    
    func updateOpponentReaction() {
        guard let reaction = getReaction(for: model.opponentAddress) else {
            opponentReactionLabel.attributedText = nil
            opponentReactionLabel.text = nil
            return
        }
        
        let replyImageAttachment = NSTextAttachment()
        
        replyImageAttachment.image = UIImage(
            named: "avatar_bots"
        )
        
        replyImageAttachment.bounds = CGRect(
            x: .zero,
            y: -3,
            width: 15,
            height: 15
        )
        
        let imageString = NSAttributedString(attachment: replyImageAttachment)
                
        let fullString = NSMutableAttributedString(string: reaction)
        fullString.append(imageString)
        
        opponentReactionLabel.attributedText = fullString
    }
    
    func getReaction(for address: String) -> String? {
        model.reactions?.first(
            where: { $0.sender == address }
        )?.reaction
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
        
        reactionsContanerView.frame = CGRect(
            origin: .init(
                x: containerView.frame.origin.x
                + additionalWidth
                - reactionsContanerViewWidth / 2,
                y: containerView.frame.origin.y
                + containerView.frame.height
                - 10
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
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            return
        }
        
        let enabledDetectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)
        
        messageLabel.configure {
            messageLabel.enabledDetectors = enabledDetectors
            for detector in enabledDetectors {
                let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
                messageLabel.setAttributes(attributes, detector: detector)
            }
            
            messageLabel.attributedText = model.message
        }
        
        replyMessageLabel.attributedText = model.messageReply
        ownReactionLabel.text = getReaction(for: model.address)
        updateOpponentReaction()
    }
    
    /// Used to handle the cell's contentView's tap gesture.
    /// Return false when the contentView does not need to handle the gesture.
    override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        messageLabel.handleGesture(touchPoint)
    }
    
    override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        super.handleTapGesture(gesture)
        
        let touchLocation = gesture.location(in: self)
        
        if containerView.frame.contains(touchLocation) {
            actionHandler(.scrollTo(message: model))
        }
    }
}

extension ChatMessageReplyCell {
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
            self.actionHandler(.copy(text: self.model.message.string))
        }
        
        return UIMenu(title: "", children: [reply, copy, report, remove])
    }
}

extension ChatMessageReplyCell: ChatMenuManagerDelegate {
    func didReact(_ emoji: String) {
        contextMenu.dismiss()
        actionHandler(.react(id: model.id, emoji: emoji))
    }
}
