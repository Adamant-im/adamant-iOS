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
    
    private let titleLabel = UILabel(font: .systemFont(ofSize: 17), textColor: .adamant.textColor)
    private let amountLabel = UILabel(font: .systemFont(ofSize: 24), textColor: .adamant.textColor)
    private let currencyLabel = UILabel(font: .systemFont(ofSize: 20), textColor: .adamant.textColor)
    private let dateLabel = UILabel(font: .systemFont(ofSize: 16), textColor: .adamant.textColor)
    
    private let commentLabel = UILabel(
        font: .systemFont(ofSize: 14),
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
        let stack = UIStackView(arrangedSubviews: [titleLabel, moneyInfoView, dateLabel, commentLabel])
        stack.axis = .vertical
        stack.spacing = 6
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
        layer.cornerRadius = 16
        
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
    
    func update() {
        backgroundColor = model.backgroundColor
        titleLabel.text = model.title
        iconView.image = model.icon
        amountLabel.text = String(model.amount)
        currencyLabel.text = model.currency
        dateLabel.text = model.date
        commentLabel.text = model.comment
        commentLabel.isHidden = model.comment == nil
    }
}
