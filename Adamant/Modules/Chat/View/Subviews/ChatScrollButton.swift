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
    case reaction
}

final class ChatScrollButton: UIView {
    private lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.alpha = 0.5
        switch position {
        case .up:
            button.setImage(.asset(named: "scrollUp"), for: .normal)
        case .down:
            let config = UIImage.SymbolConfiguration.init(paletteColors: [.lightGray, .gray])
            let image = UIImage(systemName: "chevron.down.circle.fill")?.withConfiguration(config)
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.contentVerticalAlignment = .fill
            button.contentHorizontalAlignment = .fill
        case .reaction:
            let config = UIImage.SymbolConfiguration.init(paletteColors: [.lightGray, .gray])
            let image = UIImage(systemName: "heart.circle.fill")?.withConfiguration(config)
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.contentVerticalAlignment = .fill
            button.contentHorizontalAlignment = .fill
        }
        
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .boldSystemFont(ofSize: 10)
        label.textAlignment = .center
        label.backgroundColor = UIColor.adamant.active
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
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
    
    func updateCounter(_ count: Int) {
        counterLabel.text = count > 99 ? "99+" : "\(count)"
        counterLabel.isHidden = count == 0
    }
}

private extension ChatScrollButton {
    func configure() {
        addSubview(button)
        button.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        if position == .reaction || position == .down {
            addSubview(counterLabel)
            counterLabel.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalToSuperview().offset(-9)
                $0.width.height.equalTo(18)
            }
        }
    }
    
    @objc func onTap() {
        action?()
    }
}
