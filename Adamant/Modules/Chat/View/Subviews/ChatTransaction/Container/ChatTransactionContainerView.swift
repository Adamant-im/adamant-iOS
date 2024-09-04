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
import CommonKit

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
        stack.spacing = horizontalStackSpacing
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
        
        stack.snp.makeConstraints {
            $0.width.equalTo(Self.maxVStackWidth)
        }
        return stack
    }()
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: self)
        return view
    }()
    
    private lazy var ownReactionLabel: UILabel = {
        let label = UILabel()
        label.text = getReaction(for: model.address)
        label.backgroundColor = .adamant.pickedReactionBackground
        label.layer.cornerRadius = ownReactionSize.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        
        label.snp.makeConstraints { make in
            make.width.equalTo(ownReactionSize.width)
            make.height.equalTo(ownReactionSize.height)
        }
        
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
        
        label.snp.makeConstraints { make in
            make.width.equalTo(opponentReactionSize.width)
            make.height.equalTo(opponentReactionSize.height)
        }
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapReactionAction)
        )
        
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var chatMenuManager = ChatMenuManager(delegate: self)
    
    private let ownReactionSize = CGSize(width: 40, height: 27)
    private let opponentReactionSize = CGSize(width: maxVStackWidth, height: 27)
    private let opponentReactionImageSize = CGSize(width: 12, height: 12)
    
    static let horizontalStackSpacing: CGFloat = 12
    static let maxVStackWidth: CGFloat = 55
    
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
            $0.horizontalEdges.equalToSuperview()
        }
        
        swipeView.swipeStateAction = { [actionHandler] state in
            actionHandler(.swipeState(state: state))
        }
        
        chatMenuManager.setup(for: contentView)
    }
    
    func update() {
        contentView.model = model.content
        updateStatus(model.status)
        updateLayout()
        
        ownReactionLabel.isHidden = getReaction(for: model.address) == nil
        opponentReactionLabel.isHidden = getReaction(for: model.opponentAddress) == nil
        updateOwnReaction()
        updateOpponentReaction()
        
        swipeView.didSwipeAction = { [actionHandler, model] in
            actionHandler(.reply(message: model))
        }
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
        ownReactionLabel.backgroundColor = .adamant.pickedReactionBackground
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
        opponentReactionLabel.backgroundColor = .adamant.pickedReactionBackground
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
    
    @objc func tapReactionAction() {
        chatMenuManager.presentMenuProgrammatically(for: contentView)
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
        case .notInitiated: return .asset(named: "status_updating") ?? .init()
        case .pending, .registered, .noNetwork, .noNetworkFinal: return .asset(named: "status_pending") ?? .init()
        case .success: return .asset(named: "status_success") ?? .init()
        case .failed: return .asset(named: "status_failed") ?? .init()
        case .inconsistent: return .asset(named: "status_warning") ?? .init()
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .notInitiated: return .adamant.secondary
        case .pending, .registered, .noNetwork, .noNetworkFinal: return .adamant.primary
        case .success: return .adamant.active
        case .failed, .inconsistent: return .adamant.attention
        }
    }
}

extension ChatTransactionContainerView {
    func makeContextMenu() -> AMenuSection {
        let remove = AMenuItem.action(
            title: .adamant.chat.remove,
            systemImageName: "trash",
            style: .destructive
        ) { [actionHandler, model] in
            actionHandler(.remove(id: model.id))
        }
        
        let report = AMenuItem.action(
            title: .adamant.chat.report,
            systemImageName: "exclamationmark.bubble"
        ) { [actionHandler, model] in
            actionHandler(.report(id: model.id))
        }
        
        let reply = AMenuItem.action(
            title: .adamant.chat.reply,
            systemImageName: "arrowshape.turn.up.left"
        ) { [actionHandler, model] in
            actionHandler(.reply(message: model))
        }
        
        return AMenuSection([reply, report, remove])
    }
}

extension ChatTransactionContainerView: ChatMenuManagerDelegate {
    func getCopyView() -> UIView? {
        copy(with: model)?.contentView
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

extension ChatTransactionContainerView {
    func copy(with model: Model) -> ChatTransactionContainerView? {
        let view = ChatTransactionContainerView(frame: frame)
        view.contentView.model = model.content
        view.updateStatus(model.status)
        view.updateLayout()
        view.contentView.setFixWidth(width: contentView.frame.width)
        return view
    }
}
