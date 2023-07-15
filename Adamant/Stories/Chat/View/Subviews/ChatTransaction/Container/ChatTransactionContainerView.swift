//
//  ChatTransactionContainerView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import Combine
import SwiftUI
import AdvancedContextMenuKit

final class ChatTransactionContainerView: UIView, ChatModelView {
    // MARK: Dependencies
    
    var chatMessagesListViewModel: ChatMessagesListViewModel?
    
    // MARK: Proprieties
    
    var subscription: AnyCancellable?
    
    var model: Model = .default {
        didSet { update() }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in } {
        didSet { contentView.actionHandler = actionHandler }
    }
    
    private let contentView = ChatTransactionContentView()
    
    private lazy var statusButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(onStatusButtonTap), for: .touchUpInside)
        return button
    }()
    
    private let spacingView: UIView = {
        let view = UIView()
        view.setContentCompressionResistancePriority(.dragThatCanResizeScene, for: .horizontal)
        return view
    }()
    
    private let horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 12
        return stack
    }()
    
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 12

        stack.addArrangedSubview(statusButton)
        stack.addArrangedSubview(ownReactionLabel)
        stack.addArrangedSubview(opponentReactionLabel)
        return stack
    }()
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: self)
        return view
    }()
    
    private lazy var ownReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.address)
        label.backgroundColor = .adamant.active
        label.layer.cornerRadius = ownReactionSize.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        
        label.snp.makeConstraints { make in
            make.width.equalTo(ownReactionSize.width)
            make.height.equalTo(ownReactionSize.height)
        }
        
        let eraseTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(eraseReactionAction)
        )
        
        label.addGestureRecognizer(eraseTapGesture)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var opponentReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.opponentAddress)
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.backgroundColor = .adamant.codeBlock
        label.layer.cornerRadius = 15
        
        label.snp.makeConstraints { make in
            make.width.equalTo(opponentReactionSize.width)
            make.height.equalTo(opponentReactionSize.height)
        }
        return label
    }()
    
    private lazy var chatMenuManager: ChatMenuManager = {
        let manager = ChatMenuManager(
            menu: makeContextMenu(),
            menuAlignment: model.isFromCurrentSender
            ? Alignment.trailing
            : Alignment.leading,
            emojiService: chatMessagesListViewModel?.emojiService
        )
        manager.delegate = self
        return manager
    }()
    
    private lazy var contextMenu = AdvancedContextMenuManager(delegate: chatMenuManager)
    
    private let ownReactionSize = CGSize(width: 40, height: 30)
    private let opponentReactionSize = CGSize(width: 55, height: 30)
    private let opponentReactionImageSize = CGSize(width: 10, height: 12)
    
    var isSelected: Bool = false {
        didSet {
            contentView.isSelected = isSelected
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
}

extension ChatTransactionContainerView: ReusableView {
    func prepareForReuse() {
        model = .default
        actionHandler = { _ in }
    }
}

private extension ChatTransactionContainerView {
    func configure() {
        addSubview(swipeView)
        swipeView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        
        swipeView.didSwipeAction = { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.reply(message: self.model))
        }
        
        swipeView.swipeStateAction = { [weak self] state in
            self?.actionHandler(.swipeState(state: state))
        }
        
        contextMenu.setup(for: contentView)
    }
    
    func update() {
        contentView.model = model.content
        updateStatus(model.status)
        updateLayout()
        chatMenuManager.menuAlignment = model.isFromCurrentSender
        ? Alignment.trailing
        : Alignment.leading
        chatMenuManager.selectedEmoji = getReaction(for: model.address)
        
        ownReactionLabel.isHidden = getReaction(for: model.address) == nil
        opponentReactionLabel.isHidden = getReaction(for: model.opponentAddress) == nil
        updateOwnReaction()
        updateOpponentReaction()
    }
    
    func updateStatus(_ status: TransactionStatus) {
        statusButton.setImage(status.image, for: .normal)
        statusButton.tintColor = status.imageTintColor
    }
    
    func updateLayout() {
        var viewsList = [spacingView, vStack, contentView]
        
        viewsList = model.isFromCurrentSender
            ? viewsList
            : viewsList.reversed()
        
        guard horizontalStack.arrangedSubviews != viewsList else { return }
        horizontalStack.arrangedSubviews.forEach(horizontalStack.removeArrangedSubview)
        viewsList.forEach(horizontalStack.addArrangedSubview)
    }
    
    @objc func onStatusButtonTap() {
        actionHandler(.forceUpdateTransactionStatus(id: model.id))
    }
    
    func updateOwnReaction() {
        ownReactionLabel.text = getReaction(for: model.address)
        ownReactionLabel.transform = .identity
        ownReactionLabel.alpha = 1.0
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
    }
    
    func getReaction(for address: String) -> String? {
        model.reactions?.first(
            where: { $0.sender == address }
        )?.reaction
    }
    
    @objc func eraseReactionAction() {
        animateErase { [weak self] in
            guard let self = self else { return }
            self.actionHandler(.react(id: self.model.id, emoji: ""))
        }
    }
    
    func animateErase(_ completion: (() -> Void)? = nil) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.5) {
            self.ownReactionLabel.transform = .init(scaleX: 1.3, y: 1.3)
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.25) {
                self?.ownReactionLabel.transform = .init(scaleX: 0.1, y: 0.1)
                self?.ownReactionLabel.alpha = 0
            } completion: { _ in
                completion?()
            }
        }
    }
}

extension ChatTransactionContainerView.Model {
    func height(for width: CGFloat) -> CGFloat {
        content.height(for: width)
    }
}

private extension TransactionStatus {
    var image: UIImage {
        switch self {
        case .notInitiated: return #imageLiteral(resourceName: "status_updating")
        case .pending, .registered, .noNetwork, .noNetworkFinal: return #imageLiteral(resourceName: "status_pending")
        case .success: return #imageLiteral(resourceName: "status_success")
        case .failed: return #imageLiteral(resourceName: "status_failed")
        case .inconsistent: return #imageLiteral(resourceName: "status_warning")
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .notInitiated: return .adamant.secondary
        case .pending, .registered, .noNetwork, .noNetworkFinal: return .adamant.primary
        case .success: return .adamant.active
        case .failed, .inconsistent: return .adamant.alert
        }
    }
}

extension ChatTransactionContainerView {
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
        
        return UIMenu(title: "", children: [reply, report, remove])
    }
}

extension ChatTransactionContainerView: ChatMenuManagerDelegate {
    func didReact(_ emoji: String) {
        contextMenu.dismiss()
        actionHandler(.react(id: model.id, emoji: emoji))
    }
}
