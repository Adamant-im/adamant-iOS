//
//  FullscreenAlertView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import SnapKit

final class FullscreenAlertView: UIView {
    var message: String = .empty {
        didSet { messageLabel.text = message }
    }
    
    private let containerView: UIView = .init()
    private let imageView = UIImageView(image: warningImage)
    
    private let messageLabel = UILabel(
        font: .systemFont(ofSize: 15),
        textColor: .adamant.textColor,
        numberOfLines: .zero,
        alignment: .center
    )
    
    private lazy var verticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageView, messageLabel])
        stack.axis = .vertical
        stack.spacing = 15
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
}

private extension FullscreenAlertView {
    func configure() {
        backgroundColor = .black.withAlphaComponent(0.4)
        containerView.backgroundColor = .adamant.cellColor
        containerView.layer.cornerRadius = 15
        imageView.tintColor = .adamant.primary
        imageView.contentMode = .scaleAspectFit
        
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.leading.greaterThanOrEqualToSuperview().inset(15)
            $0.bottom.trailing.lessThanOrEqualToSuperview().inset(15)
        }
        
        containerView.addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(15)
        }
    }
}

private let warningImage = UIImage(
    systemName: "exclamationmark.triangle.fill",
    withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
)!
