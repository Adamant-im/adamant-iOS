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

final class ChatMessageReplyCell: MessageContentCell, ChatModelView {    
    /// The labels used to display the message's text.
    private var messageLabel = MessageLabel()
    private var replyMessageLabel = UILabel()
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: contentView, messagePadding: 8)
        return view
    }()
    
    static let replyViewHeight: CGFloat = 25
    
    private lazy var replyView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray.withAlphaComponent(0.15)
        view.layer.cornerRadius = 5
        
        let colorView = UIView()
        colorView.layer.cornerRadius = 2
        colorView.backgroundColor = .adamant.active
        
        view.addSubview(colorView)
        view.addSubview(replyMessageLabel)
        
        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        replyMessageLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-5)
            $0.leading.equalTo(colorView.snp.trailing).offset(3)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(Self.replyViewHeight)
        }
        return view
    }()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyView, messageLabel])
        stack.axis = .vertical
        stack.spacing = 10
        return stack
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
            swipeView.update(model)
            let isSelected = oldValue.animationId != model.animationId
            && !model.animationId.isEmpty
            && oldValue.id == model.id
            && !model.id.isEmpty
            
            if isSelected {
                messageContainerView.startBlinkAnimation()
            }
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    var subscription: AnyCancellable?
    
    // MARK: - Methods
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageLabel.font = attributes.messageLabelFont
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        messageLabel.text = nil
        replyMessageLabel.attributedText = nil
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        contentView.addSubview(swipeView)
        swipeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.top.equalToSuperview()
        }
        
        swipeView.action = { [weak self] message in
            print("message id \(message.id), text = \(message.makeReplyContent().string)")
            self?.actionHandler(.reply(message: message))
        }
        
        swipeView.swipeStateAction = { [weak self] state in
            self?.actionHandler(.swipeState(state: state))
        }
        
        messageContainerView.addSubview(verticalStack)
        messageLabel.numberOfLines = 0
        replyMessageLabel.numberOfLines = 1
        verticalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
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
        
        updateFrames()
    }
    
    func updateFrames() {
        let size = messageContainerView.frame.size
        messageContainerView.frame = CGRect(
            origin: messageContainerView.frame.origin,
            size: CGSize(
                width: size.width,
                height: model.contentHeight(for: size.width)
            )
        )
        
        let origin = CGPoint(
          x: 0,
          y: messageContainerView.frame.maxY
        )
        messageBottomLabel.frame = CGRect(origin: origin, size: messageBottomLabel.frame.size)
    }
    
    /// Used to handle the cell's contentView's tap gesture.
    /// Return false when the contentView does not need to handle the gesture.
    override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        messageLabel.handleGesture(touchPoint)
    }
    
    override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        super.handleTapGesture(gesture)
        
        actionHandler(.scrollTo(message: model))
    }
}
