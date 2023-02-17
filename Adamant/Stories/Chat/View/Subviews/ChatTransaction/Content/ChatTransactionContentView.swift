//
//  ChatTransactionContentView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatTransactionContentView: UIView {
    var model: Model = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
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
            $0.size.equalTo(iconSize)
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
        let stack = UIStackView(arrangedSubviews: [titleLabel, moneyInfoView, dateLabel, commentLabel])
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

extension ChatTransactionContentView.Model {
    func height(for width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: .infinity)
        let titleString = NSAttributedString(string: title, attributes: [.font: titleFont])
        let dateString = NSAttributedString(string: date, attributes: [.font: titleFont])
        let commentString = comment.map {
            NSAttributedString(string: $0, attributes: [.font: titleFont])
        }
        
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
        
        let commentHeight: CGFloat = commentString?.boundingRect(
            with: maxSize,
            options: .usesLineFragmentOrigin,
            context: nil
        ).height ?? .zero
        
        return verticalInsets * 2
            + verticalStackSpacing * 3
            + iconSize
            + titleHeight
            + dateHeight
            + commentHeight
    }
}

private extension ChatTransactionContentView {
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
        titleLabel.text = model.title
        iconView.image = model.icon
        amountLabel.text = String(model.amount)
        currencyLabel.text = model.currency
        dateLabel.text = model.date
        commentLabel.text = model.comment
        commentLabel.isHidden = model.comment == nil
    }
    
    @objc func didTap() {
        model.action.action()
    }
}

private let titleFont = UIFont.systemFont(ofSize: 17)
private let dateFont = UIFont.systemFont(ofSize: 16)
private let commentFont = UIFont.systemFont(ofSize: 14)
private let iconSize: CGFloat = 55
private let verticalStackSpacing: CGFloat = 6
private let verticalInsets: CGFloat = 8
