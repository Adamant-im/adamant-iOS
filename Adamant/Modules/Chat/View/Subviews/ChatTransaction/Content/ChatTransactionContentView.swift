//
//  ChatTransactionContentView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

final class ChatTransactionContentView: UIView {
    var model: Model = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            animateIsSelected(
                isSelected,
                originalColor: model.backgroundColor.uiColor
            )
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    private let titleLabel = UILabel(font: titleFont, textColor: .adamant.textColor)
    private let amountLabel = UILabel(font: .systemFont(ofSize: 24), textColor: .adamant.textColor)
    private let currencyLabel = UILabel(font: .systemFont(ofSize: 20), textColor: .adamant.textColor)
    private let dateLabel = UILabel(font: dateFont, textColor: .adamant.textColor)
    
    private let commentLabel = UILabel(
        font: commentFont,
        textColor: .adamant.textColor,
        numberOfLines: .zero
    )
    
    var replyViewDynamicHeight: CGFloat {
        model.isReply ? replyViewHeight : 0
    }
    
    private var replyMessageLabel = UILabel()
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .adamant.active
        return view
    }()
    
    private lazy var replyView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray.withAlphaComponent(0.15)
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        
        view.addSubview(colorView)
        view.addSubview(replyMessageLabel)
        
        replyMessageLabel.numberOfLines = 1
        
        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        replyMessageLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-5)
            $0.leading.equalTo(colorView.snp.trailing).offset(6)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(replyViewDynamicHeight)
        }
        return view
    }()
    
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
        let stack = UIStackView(arrangedSubviews: [replyView, titleLabel, moneyInfoView, dateLabel, commentLabel])
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
    
    func setFixWidth(width: CGFloat) {
        snp.remakeConstraints {
            $0.width.lessThanOrEqualTo(width)
        }
    }
}

extension ChatTransactionContentView.Model {
    @MainActor
    func height(for width: CGFloat) -> CGFloat {
        let opponentReactionWidth = ChatTransactionContainerView.maxVStackWidth
        let containerHorizontalOffset = ChatTransactionContainerView.horizontalStackSpacing * 2
        let contentHorizontalOffset = horizontalInsets * 2
        
        let maxSize = CGSize(
            width: width
            - opponentReactionWidth
            - containerHorizontalOffset
            - contentHorizontalOffset,
            height: .infinity
        )
        let titleString = NSAttributedString(string: title, attributes: [.font: titleFont])
        let dateString = NSAttributedString(string: date, attributes: [.font: dateFont])
        
        let commentString = comment?.isEmpty == true
        ? nil
        : comment.map {
            NSAttributedString(string: $0, attributes: [.font: commentFont])
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
        
        let replyViewDynamicHeight: CGFloat = isReply ? replyViewHeight : 0
        let stackSpacingCount: CGFloat = isReply ? 4 : 3
        
        return verticalStackSpacing * stackSpacingCount
            + iconSize
            + titleHeight
            + dateHeight
            + commentHeight
            + replyViewDynamicHeight
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
            $0.leading.trailing.equalToSuperview().inset(horizontalInsets)
        }
    }
    
    func update() {
        alpha = model.isHidden ? .zero : 1.0
        backgroundColor = model.backgroundColor.uiColor
        titleLabel.text = model.title
        iconView.image = model.icon
        amountLabel.text = String(model.amount)
        currencyLabel.text = model.currency
        dateLabel.text = model.date
        commentLabel.text = model.comment
        commentLabel.isHidden = model.comment == nil
        replyView.isHidden = !model.isReply
        
        if model.isReply {
            replyMessageLabel.attributedText = model.replyMessage
        } else {
            replyMessageLabel.attributedText = nil
        }
        
        replyView.snp.updateConstraints { make in
            make.height.equalTo(replyViewDynamicHeight)
        }
    }
    
    @objc func didTap(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        
        if replyView.frame.contains(touchLocation) {
            actionHandler(.scrollTo(message: .init(
                id: model.id,
                replyId: model.replyId,
                message: NSAttributedString(string: ""),
                messageReply: NSAttributedString(string: ""),
                backgroundColor: .failed,
                isFromCurrentSender: true,
                reactions: nil,
                address: "",
                opponentAddress: "",
                isHidden: false
            )))
            return
        }
        
        actionHandler(.openTransactionDetails(id: model.id))
    }
}

private let titleFont = UIFont.systemFont(ofSize: 17)
private let dateFont = UIFont.systemFont(ofSize: 16)
private let commentFont = UIFont.systemFont(ofSize: 14)
private let iconSize: CGFloat = 55
private let verticalStackSpacing: CGFloat = 6
private let verticalInsets: CGFloat = 8
private let horizontalInsets: CGFloat = 12
private let replyViewHeight: CGFloat = 25
