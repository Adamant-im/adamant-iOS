//
//  ChatScrollDownButton.swift
//  Adamant
//
//  Created by Andrey Golubenko on 19.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatScrollDownButton: UIView {
    private lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.asset(named: "ScrollDown"), for: .normal)
        button.alpha = 0.5
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        return button
    }()
    
    var action: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatScrollDownButton {
    func configure() {
        addSubview(button)
        button.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    @objc func onTap() {
        action?()
    }
}
