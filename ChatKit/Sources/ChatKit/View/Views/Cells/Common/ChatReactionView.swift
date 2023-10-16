//
//  ChatReactionView.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import UIKit
import SnapKit
import CommonKit

final class ChatReactionView: UIView, Modelable {
    var modelStorage: ChatReactionModel = .default {
        didSet { update() }
    }
    
    private let emojiLabel = UILabel()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var horizontalStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [imageView, emojiLabel])
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 4
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

private extension ChatReactionView {
    func configure() {
        backgroundColor = .adamant.pickedReactionBackground
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(8)
            $0.directionalVerticalEdges.equalToSuperview().inset(4)
        }
        
        imageView.snp.makeConstraints {
            $0.size.lessThanOrEqualTo(12)
            $0.height.lessThanOrEqualTo(emojiLabel.snp.height)
        }
        
        update()
    }
    
    func update() {
        emojiLabel.text = model.emoji
        imageView.image = model.image
        imageView.isHidden = model.image == nil
    }
    
    @objc func onTap() {
        model.onTap.action()
    }
}
