//
//  ChatReplyContentView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatReplyContentView: UIView {
    var model: Model = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    private let messageLabel = UILabel(font: messageFont, textColor: .adamant.textColor, numberOfLines: 0)
    private let replyLabel = UILabel(font: replyFont, textColor: .adamant.textColor, numberOfLines: 0)
    
    private lazy var replyView: UIView = {
        let view = UIView()
        let colorView = UIView()
        colorView.backgroundColor = .adamant.active
        
        view.addSubview(colorView)
        view.addSubview(replyLabel)

        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        replyLabel.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(colorView.snp.trailing).offset(3)
        }
        return view
    }()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyView, messageLabel])
        stack.axis = .vertical
        stack.spacing = verticalStackSpacing
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

extension ChatReplyContentView.Model {
    func height(for width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: .infinity)
        let titleString = NSAttributedString(string: message, attributes: [.font: messageFont])
        let dateString = NSAttributedString(string: messageReply, attributes: [.font: replyFont])
        
        let titleHeight = titleString.boundingRect(
            with: maxSize,
            options: .usesLineFragmentOrigin,
            context: nil
        ).height
        
        let dateHeight = dateString.boundingRect(
            with: maxSize,
            options: .usesLineFragmentOrigin,
            context: nil
        ).height
        
        return verticalInsets * 2
            + verticalStackSpacing * 3
            + titleHeight
            + dateHeight
    }
}

private extension ChatReplyContentView {
    func configure() {
        layer.cornerRadius = 16
        
        addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(didTap)
        ))
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(verticalInsets)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
    
    func update() {
        backgroundColor = model.backgroundColor.uiColor
        messageLabel.text = model.message
        replyLabel.text = model.messageReply
    }
    
    @objc func didTap() {
       // actionHandler(.scrollToMessage(id: model.id))
    }
}

private let messageFont = UIFont.systemFont(ofSize: 17)
private let replyFont = UIFont.systemFont(ofSize: 16)
private let verticalStackSpacing: CGFloat = 6
private let verticalInsets: CGFloat = 8
