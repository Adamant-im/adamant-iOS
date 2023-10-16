//
//  ChatMessageContentView.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import UIKit
import CommonKit

final class ChatMessageContentView: UIView, Modelable {
    static let verticalInset: CGFloat = 6
    
    var modelStorage: ChatMessageContentModel = .default {
        didSet { update() }
    }
    
    private let replyView = ChatReplyView()
    
    private let messageLabel: ClickableLabel = {
        let view = ClickableLabel(clickableTypes: [.link])
        view.numberOfLines = .zero
        view.colors = [.link: .adamant.active]
        return view
    }()
    
    private lazy var verticalStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [replyView, messageLabel])
        view.axis = .vertical
        view.spacing = Self.verticalInset
        return view
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

private extension ChatMessageContentView {
    func configure() {
        layer.cornerRadius = 12
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.directionalVerticalEdges.equalToSuperview().inset(Self.verticalInset)
            $0.directionalHorizontalEdges.equalToSuperview().inset(12)
        }
        
        update()
    }
    
    func update() {
        replyView.model = model.reply ?? .default
        replyView.isHidden = model.reply == nil
        messageLabel.attributedText = model.text
        backgroundColor = model.status.backgroundColor
    }
}
