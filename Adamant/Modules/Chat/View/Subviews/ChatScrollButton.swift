//
//  ChatScrollDownButton.swift
//  Adamant
//
//  Created by Andrey Golubenko on 19.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

enum Position {
    case up
    case down
}

final class ChatScrollButton: UIView {
    private lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.alpha = 0.5
        switch position {
        case .up:
            button.setImage(.asset(named: "scrollUp"), for: .normal)
        case .down:
            button.setImage(.asset(named: "ScrollDown"), for: .normal)
        }
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        return button
    }()
    
    private let position: Position
    
    var action: (() -> Void)?
    
    init(frame: CGRect = .zero, position: Position) {
        self.position = position
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        self.position = .down
        super.init(coder: coder)
        configure()
    }
}

private extension ChatScrollButton {
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
