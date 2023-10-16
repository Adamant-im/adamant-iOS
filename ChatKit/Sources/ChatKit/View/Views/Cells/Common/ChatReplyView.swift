//
//  ChatReplyView.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import UIKit
import SnapKit
import CommonKit

final class ChatReplyView: UIView, Modelable {
    var modelStorage: ChatReplyModel = .default {
        didSet { update() }
    }
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .adamant.active
        return view
    }()
    
    private let replyLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatReplyView {
    func configure() {
        backgroundColor = .lightGray.withAlphaComponent(0.15)
        layer.cornerRadius = 8
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        
        addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.width.equalTo(2)
        }
        
        addSubview(replyLabel)
        replyLabel.snp.makeConstraints {
            $0.directionalVerticalEdges.equalToSuperview().inset(2)
            $0.trailing.equalToSuperview().inset(replyLabelHorizontalInset)
            $0.leading.equalTo(separatorView.snp.trailing).offset(replyLabelHorizontalInset)
        }
        
        update()
    }
    
    func update() {
        replyLabel.attributedText = model.replyText
    }
    
    @objc func onTap() {
        model.onTap.action()
    }
}

private let replyLabelHorizontalInset: CGFloat = 6
