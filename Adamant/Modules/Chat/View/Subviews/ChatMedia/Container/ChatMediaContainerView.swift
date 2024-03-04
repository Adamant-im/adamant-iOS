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
    
    private lazy var contentView = ChatMediaContentView()
    
    // MARK: Proprieties
    
    var subscription: AnyCancellable?
    
    var model: Model = .default {
        didSet { update() }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in } {
        didSet { contentView.actionHandler = actionHandler }
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
        
        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        
        swipeView.swipeStateAction = { [actionHandler] state in
            actionHandler(.swipeState(state: state))
        }
     //   chatMenuManager.setup(for: contentView)
    }
    
    func update() {
        contentView.model = model.content
        
        swipeView.didSwipeAction = { [actionHandler, model] in
            actionHandler(.reply(message: model))
        }
    }
}

extension ChatMediaContainerView.Model {
    func height() -> CGFloat {
        content.height()
    }
}
