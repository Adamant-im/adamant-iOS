//
//  ChatMessageView.swift
//
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import CommonKit

final class ChatMessageView: UIView, Modelable {
    var modelStorage: ChatMessageModel = .default {
        didSet { update() }
    }
    
    private let messageLabel = ClickableLabel(clickableTypes: [.link], numberOfLines: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatMessageView: ReusableView {
    func prepareForReuse() {}
}

private extension ChatMessageView {
    func configure() {
        layer.cornerRadius = 8
        
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(4)
        }
        
        update()
    }
    
    func update() {
        backgroundColor = model.status.backgroundColor
        messageLabel.attributedText = model.text
    }
}
