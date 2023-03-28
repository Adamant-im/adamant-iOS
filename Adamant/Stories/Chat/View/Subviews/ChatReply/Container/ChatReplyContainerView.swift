//
//  ChatReplyContainerView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import Combine

final class ChatReplyContainerView: UIView {
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            update()
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in } {
        didSet { contentView.actionHandler = actionHandler }
    }
    
    private let contentView = ChatReplyContentView()
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatReplyContainerView {
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
    
    func update() {
        contentView.model = model.content
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
    
    @objc func buttonTap() {
      //  actionHandler(.scrollToMessage(id: model.id))
    }
}

extension ChatReplyContainerView.Model {
    func height(for width: CGFloat) -> CGFloat {
        content.height(for: width)
    }
}

extension ChatReplyContainerView: ReusableView {
    func prepareForReuse() {
        model = .default
        actionHandler = { _ in }
    }
}
