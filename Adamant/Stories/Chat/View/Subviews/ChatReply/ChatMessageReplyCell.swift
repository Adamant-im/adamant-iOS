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
import CommonKit

final class ChatMessageReplyCell: MessageContentCell, ChatModelView {
    // MARK: Dependencies
    
    var chatMessagesListViewModel: ChatMessagesListViewModel?
    
    // MARK: Proprieties
    
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
    
    private lazy var chatMenuManager = ChatMenuManager(delegate: self)
    
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
            
            containerView.isHidden = model.isHidden
            replyMessageLabel.attributedText = model.messageReply
            
            let leading = model.isFromCurrentSender ? smallHInset : longHInset
            let trailing = model.isFromCurrentSender ? longHInset : smallHInset
            verticalStack.snp.updateConstraints {
                $0.leading.equalToSuperview().inset(leading)
                $0.trailing.equalToSuperview().inset(trailing)
            }
            
            reactionsContanerView.isHidden = model.reactions == nil
            ownReactionLabel.isHidden = getReaction(for: model.address) == nil
            opponentReactionLabel.isHidden = getReaction(for: model.opponentAddress) == nil
            updateOwnReaction()
            updateOpponentReaction()
            layoutReactionLabel()
            
            swipeView.didSwipeAction = { [actionHandler, model] in
                actionHandler(.reply(message: model))
            }
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
    private let ownReactionSize = CGSize(width: 40, height: 27)
    private let opponentReactionSize = CGSize(width: 55, height: 27)
    private let opponentReactionImageSize = CGSize(width: 12, height: 12)
    private var layoutAttributes: MessagesCollectionViewLayoutAttributes?
    
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
        
        swipeView.swipeStateAction = { [actionHandler] state in
            actionHandler(.swipeState(state: state))
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
        
        containerView.addSubview(messageContainerView)
        chatMenuManager.setup(for: containerView)
    }
    
    func updateOwnReaction() {
        ownReactionLabel.text = getReaction(for: model.address)
        ownReactionLabel.backgroundColor = model.backgroundColor.uiColor.mixin(
            infusion: .lightGray,
            alpha: 0.15
        )
    }
    
    func updateOpponentReaction() {
        guard let reaction = getReaction(for: model.opponentAddress),
              let senderPublicKey = getSenderPublicKeyInReaction(for: model.opponentAddress)
        else {
            opponentReactionLabel.attributedText = nil
            opponentReactionLabel.text = nil
            return
        }
        
        let fullString = NSMutableAttributedString(string: reaction)
        
        if let image = chatMessagesListViewModel?.avatarService.avatar(
            for: senderPublicKey,
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
    
    func getSenderPublicKeyInReaction(for senderAddress: String) -> String? {
        model.reactions?.first(
            where: { $0.sender == senderAddress }
        )?.senderPublicKey
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
        updateOwnReaction()
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
    func makeContextMenu() -> AMenuSection {
        let remove = AMenuItem.action(
            title: .adamant.chat.remove,
            systemImageName: "trash",
            style: .destructive
        ) { [actionHandler, id = model.id] in
            actionHandler(.remove(id: id))
        }
        
        let report = AMenuItem.action(
            title: .adamant.chat.report,
            systemImageName: "exclamationmark.bubble"
        ) { [actionHandler, id = model.id] in
            actionHandler(.report(id: id))
        }
        
        let reply = AMenuItem.action(
            title: .adamant.chat.reply,
            systemImageName: "arrowshape.turn.up.left"
        ) { [actionHandler, model] in
            actionHandler(.reply(message: model))
        }
        
        let copy = AMenuItem.action(
            title: .adamant.chat.copy,
            systemImageName: "doc.on.doc"
        ) { [actionHandler, model] in
            actionHandler(.copy(text: model.message.string))
        }
        
        return AMenuSection([reply, copy, report, remove])
    }
    
    @objc func tapReactionAction() {
        chatMenuManager.presentMenuProgrammatically(for: containerView)
    }
}

extension ChatMessageReplyCell: ChatMenuManagerDelegate {
    func getCopyView() -> UIView? {
        copy(
            with: model,
            attributes: layoutAttributes,
            urlAttributes: messageLabel.urlAttributes,
            enabledDetectors: messageLabel.enabledDetectors
        )?.containerView
    }
    
    func presentMenu(
        copyView: UIView,
        size: CGSize,
        location: CGPoint,
        tapLocation: CGPoint,
        getPositionOnScreen: @escaping () -> CGPoint
    ) {
        let arguments = ChatContextMenuArguments.init(
            copyView: copyView,
            size: size,
            location: location,
            tapLocation: tapLocation,
            messageId: model.id,
            menu: makeContextMenu(),
            selectedEmoji: getReaction(for: model.address),
            getPositionOnScreen: getPositionOnScreen
        )
        actionHandler(.presentMenu(arg: arguments))
    }
}

extension ChatMessageReplyCell {
    func copy(
        with model: Model,
        attributes: MessagesCollectionViewLayoutAttributes?,
        urlAttributes: [NSAttributedString.Key : Any],
        enabledDetectors: [DetectorType]
    ) -> ChatMessageReplyCell? {
        guard let attributes = attributes else { return nil }
        
        let cell = ChatMessageReplyCell(frame: frame)
        cell.apply(attributes)

        cell.replyMessageLabel.attributedText = model.messageReply
        let leading = model.isFromCurrentSender ? cell.smallHInset : cell.longHInset
        let trailing = model.isFromCurrentSender ? cell.longHInset : cell.smallHInset
        
        cell.verticalStack.snp.updateConstraints {
            $0.leading.equalToSuperview().inset(leading)
            $0.trailing.equalToSuperview().inset(trailing)
        }
        
        cell.messageContainerView.backgroundColor = model.backgroundColor.uiColor
        cell.messageLabel.configure {
            cell.messageLabel.enabledDetectors = enabledDetectors
            cell.messageLabel.setAttributes(urlAttributes, detector: .url)
            cell.messageLabel.attributedText = model.message
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
