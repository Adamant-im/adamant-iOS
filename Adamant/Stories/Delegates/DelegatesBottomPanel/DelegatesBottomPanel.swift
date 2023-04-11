//
//  DelegatesBottomPanel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class DelegatesBottomPanel: UIView {
    var model: Model = .default {
        didSet { update() }
    }
    
    private let upVotesLabel = UILabel(font: .systemFont(ofSize: 16), textColor: .adamant.textColor)
    private let downVotesLabel = UILabel(font: .systemFont(ofSize: 16), textColor: .adamant.textColor)
    private let newVotesLabel = UILabel(font: .systemFont(ofSize: 16), textColor: .adamant.textColor)
    private let totalVotesLabel = UILabel(font: .systemFont(ofSize: 16), textColor: .adamant.textColor)
    private let costLabel = UILabel(font: .systemFont(ofSize: 12), textColor: .adamant.textColor)
    
    private lazy var sendButton: UIButton = {
        let view = UIButton.systemButton(with: #imageLiteral(resourceName: "Arrow"), target: self, action: #selector(send))
        view.tintColor = .systemBlue
        return view
    }()
    
    private lazy var leftStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [upVotesLabel, downVotesLabel])
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = spacing
        return view
    }()
    
    private lazy var centralStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [newVotesLabel, totalVotesLabel])
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = spacing
        return view
    }()
    
    private lazy var rightStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [costLabel, sendButton])
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = spacing
        return view
    }()
    
    private lazy var horizontalStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [leftStack, centralStack, rightStack])
        view.axis = .horizontal
        view.distribution = .equalSpacing
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(frame: .zero)
        setup()
    }
}

private extension DelegatesBottomPanel {
    func setup() {
        backgroundColor = .adamant.secondBackgroundColor
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(spacing)
        }
        
        update()
    }
    
    func update() {
        upVotesLabel.text = "\(upvotesPrefix) \(model.upvotes)"
        downVotesLabel.text = "\(downvotesPrefix) \(model.downvotes)"
        costLabel.text = model.cost
        sendButton.isEnabled = model.isSendingEnabled
        
        newVotesLabel.attributedText = makeString(
            prefix: newPrefix,
            string: "\(model.new.0)/\(model.new.1)",
            color: model.newVotesColor
        )
        
        totalVotesLabel.attributedText = makeString(
            prefix: totalPrefix,
            string: "\(model.total.0)/\(model.total.1)",
            color: model.totalVotesColor
        )
    }
    
    func makeString(prefix: String, string: String, color: UIColor) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        let attrString = NSMutableAttributedString(string: prefix + " ")
        attrString.append(.init(string: string, attributes: attributes))
        return attrString
    }
    
    @objc func send() {
        model.sendAction()
    }
}

private let upvotesPrefix = NSLocalizedString(
    "Delegates.VotePanel.Upvotes",
    comment: "Delegate vote panel: 'Upvotes' label"
)

private let downvotesPrefix = NSLocalizedString(
    "Delegates.VotePanel.Downvotes",
    comment: "Delegate vote panel: 'Downvotes' label"
)

private let newPrefix = NSLocalizedString(
    "Delegates.VotePanel.New",
    comment: "Delegate vote panel: 'New' label"
)

private let totalPrefix = NSLocalizedString(
    "Delegates.VotePanel.Total",
    comment: "Delegate vote panel: 'Total' label"
)

private let spacing: CGFloat = 8
