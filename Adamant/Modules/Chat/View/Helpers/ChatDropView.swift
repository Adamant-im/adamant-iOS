//
//  ChatDropView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatDropView: UIView {
    private lazy var imageView = UIImageView(image: .asset(named: "uploadIcon"))
    private lazy var titleLabel = UILabel(font: titleFont, textColor: .lightGray)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatDropView {
    func configure() {
        layer.cornerRadius = 5
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.adamant.active.cgColor
        backgroundColor = .systemBackground
        
        titleLabel.text = dropTitle
        imageView.tintColor = .lightGray
        
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-15)
            make.size.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
    }
}

private let titleFont = UIFont.systemFont(ofSize: 20)
private var dropTitle: String { .localized("Chat.Drop.Title") }
