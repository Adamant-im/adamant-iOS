//
//  ReplyView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

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
            image: UIImage(
                systemName: "arrowshape.turn.up.left"
            )?.withTintColor(.adamant.active)
        )
        
        iv.tintColor = .adamant.active
        iv.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(24)
        }
        
        return iv
    }()
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(
            UIImage(systemName: "xmark")?.withTintColor(.adamant.attention),
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
            $0.verticalEdges.equalToSuperview().inset(verticalInsets)
            $0.horizontalEdges.equalToSuperview().inset(horizontalInsets)
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
        var text = model.makeReplyContent().resolveLinkColor()
        text = MessageProcessHelper.process(attributedText: text)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        text.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: .init(location: .zero, length: text.length)
        )

        messageLabel.attributedText = text
    }
}

private let messageFont = UIFont.systemFont(ofSize: 14)
private let horizontalStackSpacing: CGFloat = 25
private let verticalInsets: CGFloat = 8
private let horizontalInsets: CGFloat = 12
