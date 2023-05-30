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

final class ChatTransactionContainerView: UIView, ChatModelView {
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
    
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: self)
        return view
    }()
    
    private lazy var chatMenuManager: ChatMenuManager = {
        let manager = ChatMenuManager(
            menu: makeContextMenu(),
            backgroundColor: nil
        )
        return manager
    }()
    
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
    
    func configureColor() {
        contentView.backgroundColor = model.content.backgroundColor.uiColor
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
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        
        swipeView.action = { [weak self] message in
            self?.actionHandler(.reply(message: message))
        }
        
        swipeView.swipeStateAction = { [weak self] state in
            self?.actionHandler(.swipeState(state: state))
        }
        
        let interaction = UIContextMenuInteraction(delegate: chatMenuManager)
        contentView.addInteraction(interaction)
    }
    
    func update() {
        swipeView.update(model)
        contentView.model = model.content
        updateStatus(model.status)
        updateLayout()
    }
    
    func updateStatus(_ status: TransactionStatus) {
        statusButton.setImage(status.image, for: .normal)
        statusButton.tintColor = status.imageTintColor
    }
    
    func updateLayout() {
        var viewsList = [spacingView, statusButton, contentView]
        
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
