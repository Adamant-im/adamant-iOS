//
//  ChatMediaContainerView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import Combine
import CommonKit

final class ChatMediaContainerView: UIView, ChatModelView {
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: self)
        return view
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
        return stack
    }()
    
    private lazy var contentView = ChatMediaContentView()
    private lazy var chatMenuManager = ChatMenuManager(delegate: self)

    // MARK: Proprieties
    
    var subscription: AnyCancellable?
    
    var model: Model = .default {
        didSet { update() }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in } {
        didSet { contentView.actionHandler = actionHandler }
    }
    
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

extension ChatMediaContainerView {
    func configure() {        
        addSubview(swipeView)
        swipeView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(4)
        }
        
        swipeView.swipeStateAction = { [actionHandler] state in
            actionHandler(.swipeState(state: state))
        }
        
        contentView.snp.makeConstraints { $0.width.equalTo(contentWidth) }
        
        chatMenuManager.setup(for: contentView)
    }
    
    func update() {
        contentView.model = model.content
        
        swipeView.didSwipeAction = { [actionHandler, model] in
            actionHandler(.reply(message: model))
        }
        
        updateLayout()
    }
    
    func updateLayout() {
        var viewsList = [spacingView, contentView]
        
        viewsList = model.isFromCurrentSender
            ? viewsList
            : viewsList.reversed()
        
        guard horizontalStack.arrangedSubviews != viewsList else { return }
        horizontalStack.arrangedSubviews.forEach(horizontalStack.removeArrangedSubview)
        viewsList.forEach(horizontalStack.addArrangedSubview)
    }
}

extension ChatMediaContainerView: ChatMenuManagerDelegate {
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
            selectedEmoji: nil,
            getPositionOnScreen: getPositionOnScreen
        )
        actionHandler(.presentMenu(arg: arguments))
    }
}

extension ChatMediaContainerView {
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

extension ChatMediaContainerView {
    func copy(with model: Model) -> ChatMediaContainerView? {
        let view = ChatMediaContainerView(frame: frame)
        view.contentView.model = model.content
        return view
    }
}

extension ChatMediaContainerView.Model {
    func height() -> CGFloat {
        content.height()
    }
}

private let contentWidth: CGFloat = 260
