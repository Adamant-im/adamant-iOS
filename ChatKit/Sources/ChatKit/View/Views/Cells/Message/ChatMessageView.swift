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
        didSet { update(old: oldValue) }
    }
    
    private let topLabel = UILabel()
    private let contentView = ChatMessageContentView()
    private let bottomLabel = UILabel()
    
    private lazy var verticalStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [topLabel, contentView, bottomLabel])
        view.axis = .vertical
        view.spacing = 2
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

private extension ChatMessageView {
    func configure() {
        addSubview(verticalStack)
        updateLayout()
        update(old: model)
    }
    
    func update(old: ChatMessageModel) {
        topLabel.attributedText = model.topString
        topLabel.isHidden = model.topString == nil
        contentView.model = model.content
        bottomLabel.attributedText = model.bottomString
        
        guard old.isSentByPartner != model.isSentByPartner else { return }
        updateLayout()
    }
    
    func updateLayout() {
        verticalStack.alignment = model.isSentByPartner
            ? .leading
            : .trailing
        
        verticalStack.snp.remakeConstraints {
            $0.directionalVerticalEdges.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview().multipliedBy(0.9)
            
            if model.isSentByPartner {
                $0.leading.lessThanOrEqualToSuperview()
            } else {
                $0.trailing.lessThanOrEqualToSuperview()
            }
        }
    }
}

private extension ChatMessageModel {
    var isSentByPartner: Bool {
        content.status.isSentByPartner
    }
}
