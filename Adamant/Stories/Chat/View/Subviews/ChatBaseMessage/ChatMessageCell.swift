//
//  ChatBaseTextMessageView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import MessageKit

class ChatMessageCell: TextMessageCell {
    private lazy var swipeView: SwipeableView = {
        let view = SwipeableView(frame: .zero, view: contentView, messagePadding: 8)
        return view
    }()
    
    // MARK: - Properties
    
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            swipeView.update(model)
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    // MARK: - Methods
    
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
    }
}
