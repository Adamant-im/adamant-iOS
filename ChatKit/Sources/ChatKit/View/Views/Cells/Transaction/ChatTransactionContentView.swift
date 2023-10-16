//
//  ChatTransactionContentView.swift
//  
//
//  Created by Andrew G on 16.10.2023.
//

import UIKit
import SnapKit
import CommonKit

final class ChatTransactionContentView: UIView, Modelable {
    var modelStorage: ChatTransactionContentModel = .default {
        didSet { update() }
    }
    
    private let replyView = ChatReplyView()
    private let titleLabel = UILabel(font: titleFont, textColor: .adamant.textColor)
    private let amountLabel = UILabel(font: .systemFont(ofSize: 24), textColor: .adamant.textColor)
    private let currencyLabel = UILabel(font: .systemFont(ofSize: 20), textColor: .adamant.textColor)
    private let dateLabel = UILabel(font: dateFont, textColor: .adamant.textColor)
    
    private let commentLabel = UILabel(
        font: commentFont,
        textColor: .adamant.textColor,
        numberOfLines: .zero
    )
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var moneyInfoView: UIView = {
        let view = UIView()
        view.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.size.equalTo(55)
        }
        
        view.addSubview(amountLabel)
        amountLabel.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
        }
        
        view.addSubview(currencyLabel)
        currencyLabel.snp.makeConstraints {
            $0.top.equalTo(amountLabel.snp.bottom)
            $0.leading.equalTo(amountLabel.snp.leading)
            $0.trailing.equalToSuperview()
        }
        
        return view
    }()
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            replyView,
            titleLabel,
            moneyInfoView,
            dateLabel,
            commentLabel
        ])
        
        stack.axis = .vertical
        stack.spacing = 4
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

private extension ChatTransactionContentView {
    func configure() {
        layer.cornerRadius = 12
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.directionalVerticalEdges.equalToSuperview().inset(8)
            $0.directionalHorizontalEdges.equalToSuperview().inset(12)
        }
        
        update()
    }
    
    func update() {
        backgroundColor = model.status.backgroundColor
        titleLabel.text = model.title
        iconView.image = model.icon
        amountLabel.text = model.amount
        currencyLabel.text = model.currency
        dateLabel.text = model.date
        commentLabel.text = model.comment
        commentLabel.isHidden = model.comment == nil
        replyView.model = model.reply ?? .default
        replyView.isHidden = model.reply == nil
    }
    
    @objc func onTap() {
        model.onTap.action()
    }
}

private let titleFont = UIFont.systemFont(ofSize: 17)
private let dateFont = UIFont.systemFont(ofSize: 16)
private let commentFont = UIFont.systemFont(ofSize: 14)
