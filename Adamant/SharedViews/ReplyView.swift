//
//  ReplyView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ReplyView: UIView {
    
    private let messageLabel = UILabel(font: messageFont, textColor: .adamant.textColor, numberOfLines: 1)
    
    private lazy var replyView: UIView = {
        let view = UIView()
        let colorView = UIView()
        colorView.backgroundColor = .adamant.active
        
        view.addSubview(colorView)
        view.addSubview(messageLabel)

        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        messageLabel.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(colorView.snp.trailing).offset(5)
        }
        return view
    }()
    
    private var replyIV: UIImageView = {
        let iv = UIImageView(
            image: UIImage(named: "reply")?.withTintColor(.adamant.active)
        )
        
        iv.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(24)
        }
        
        return iv
    }()
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(
            UIImage(systemName: "xmark")?.withTintColor(.adamant.alert),
            for: .normal
        )
        btn.addTarget(self, action: #selector(didTapCloseBtn), for: .touchUpInside)
        
        btn.snp.makeConstraints { make in
            make.height.width.equalTo(30)
        }
        return btn
    }()
    
    private lazy var horizontalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [replyIV, replyView, closeBtn])
        stack.axis = .horizontal
        stack.spacing = horizontalStackSpacing
        return stack
    }()
    
    // MARK: Proprieties
    
    var closeAction: (() -> Void)?
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(verticalInsets)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
    
    // MARK: Actions
    
    @objc private func didTapCloseBtn() {
        closeAction?()
    }
}
    
extension ReplyView {
    func update(with model: MessageModel) {
        backgroundColor = .clear
        messageLabel.attributedText = model.makeReplyContent().resolveLinkColor()
    }
}

private let messageFont = UIFont.systemFont(ofSize: 14)
private let horizontalStackSpacing: CGFloat = 20
private let verticalInsets: CGFloat = 8
