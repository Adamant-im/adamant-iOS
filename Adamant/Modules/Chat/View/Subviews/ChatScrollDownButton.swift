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
    
    private let badgeView = BadgeViewLabel()
    
    var action: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func updateCounter(count: Int) {
        badgeView.updateCounter(count: count)
    }
}

private extension ChatScrollDownButton {
    func configure() {
        addSubview(button)
        addSubview(badgeView)
        button.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        badgeView.snp.makeConstraints { make in
            make.height.equalTo(counterMinSize)
            make.width.greaterThanOrEqualTo(counterMinSize)
            make.centerY.equalTo(button.snp.top)
            make.centerX.equalTo(button.snp.centerX)
        }
    }
    
    @objc func onTap() {
        action?()
    }
}

fileprivate let counterMinSize: CGFloat = 16
