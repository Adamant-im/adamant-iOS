//
//  ChatMediaCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import MessageKit
import SnapKit
import UIKit
import CommonKit

final class ChatMediaCell: MessageContentCell, ChatModelView {
    private let containerMediaView = ChatMediaContainerView()
    private let cellContainerView = UIView()
    private lazy var swipeWrapper = ChatSwipeWrapper(cellContainerView)

    var subscription: AnyCancellable?
    var copyAction: ((String) -> Void)?
    
    // MARK: Gesture Helper
    var GestureTaskManager: TaskManager = TaskManager()
    var didPerformLongPressAction: Bool = false

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
            if isSelected && model.content.comment.string != "" {
                copyAction?(model.content.comment.string)
            }
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
    
    fileprivate func configure() {
        contentView.addSubview(swipeWrapper)
        swipeWrapper.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        configureLongPressGesture()
    }
    
    private func configureLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        cellContainerView.addGestureRecognizer(longPress)
        cellContainerView.isUserInteractionEnabled = true
    }
}

extension ChatMediaCell: GestureHelper {
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if !isMacOS, model.status == .failed {
            handleLongPressToShowFailed(gesture)
            return
        }
        if isMacOS {
            handleLongPressToCopy(gesture)
            return
        }
        handleLongPressToOpenMenu(gesture)
    }

    private func handleLongPressToCopy(_ gesture: UILongPressGestureRecognizer) {
        processLongPress(
            gesture: gesture,
            perform:     { [weak self] in
                guard let text = self?.model.content.comment.string else { return }
                self?.copyAction?(text) },
            onGestureBegan: { [weak self] in
                self?.cellContainerView.animatePressDown() },
            onGestureEnded:   { [weak self] in self?.cellContainerView.animatePressUp() }
        )
    }
    
    private func handleLongPressToShowFailed(_ gesture: UILongPressGestureRecognizer) {
        processLongPress(
            gesture: gesture,
            perform:     { [weak self] in
                guard let id = self?.model.id else { return }
                self?.actionHandler(.showFailedMessageAlert(id: id)) },
            onGestureBegan: { [weak self] in
                self?.cellContainerView.animatePressDown() },
            onGestureEnded:   { [weak self] in self?.cellContainerView.animatePressUp() }
        )
    }
    
    private func handleLongPressToOpenMenu(_ gesture: UILongPressGestureRecognizer) {
        processLongPress(
            gesture: gesture,
            touchDuration: 0.2,
            perform:     { [weak self] in
                guard let view = self?.cellContainerView else { return }
                self?.containerMediaView.presentMenuProgrammatically(for: view)
            },
            onGestureBegan: { [weak self] in
                self?.cellContainerView.animatePressDown() },
            onGestureEnded:   { [weak self] in self?.messageContainerView.animatePressUp() }
        )
    }
}

extension ChatMediaCell: ChatCellProtocol {
    func animateReactionHighlight() {
        containerMediaView.animateReactionHighlight()
    }
    
    func animateMessageHighlight() {
        containerMediaView.animateMediaHighlight()
    }
}
