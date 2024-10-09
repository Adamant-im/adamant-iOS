//
//  VisibleWalletsCheckmarkView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import SnapKit
import UIKit
import CommonKit

final class VisibleWalletsCheckmarkRowView: UIView {
    private let checkmarkView = CheckmarkView()
    private let titleLabel = makeTitleLabel()
    private let subtitleLabel = makeSubtitleLabel()
    private let captionLabel = makeCaptionLabel()
    private let logoImageView = UIImageView()
    private let balanceLabel = makeAdditionalLabel()
    
    private let awaitingValueString = "⏱"
    
    private lazy var horizontalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [captionLabel, subtitleLabel])
        stack.axis = .horizontal
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        stack.spacing = 6
        return stack
    }()
    
    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var subtitle: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }
    
    var caption: String? {
        get { captionLabel.text }
        set { captionLabel.text = newValue }
    }
    
    var balance: Decimal? {
        didSet {
            if let balance = balance {
                balanceLabel.font = balance == 0 ? captionLabel.font : titleLabel.font
                balanceLabel.textColor = balance == 0 ? captionLabel.textColor : titleLabel.textColor
                if balance < 1 {
                    balanceLabel.text = AdamantBalanceFormat.compact.format(balance)
                } else {
                    balanceLabel.text = AdamantBalanceFormat.short.format(balance)
                }
            } else {
                balanceLabel.text = awaitingValueString
            }
        }
    }
    
    var onCheckmarkTap: (() -> Void)? {
        get { checkmarkView.onCheckmarkTap }
        set { checkmarkView.onCheckmarkTap = newValue }
    }
    
    var checkmarkImage: UIImage? {
        get { checkmarkView.image }
        set { checkmarkView.image = newValue }
    }
    
    var logoImage: UIImage? {
        get { logoImageView.image }
        set { logoImageView.image = newValue }
    }
    
    var isChecked: Bool {
        checkmarkView.isChecked
    }
    
    var checkmarkImageBorderColor: UIColor? {
        get {
            guard let imageBorderColor = checkmarkView.imageBorderColor else { return nil }
            return UIColor(cgColor: imageBorderColor)
        }
        set { checkmarkView.imageBorderColor = newValue?.cgColor }
    }
    
    var checkmarkImageTintColor: UIColor? {
        get { checkmarkView.imageTintColor }
        set { checkmarkView.imageTintColor = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setIsChecked(_ isChecked: Bool, animated: Bool) {
        checkmarkView.setIsChecked(isChecked, animated: animated)
    }
    
    private func setupView() {
        addSubview(logoImageView)
        logoImageView.snp.makeConstraints {
            $0.size.equalTo(25)
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().inset(10)
        }
        
        addSubview(checkmarkView)
        checkmarkView.snp.makeConstraints {
            $0.size.equalTo(44)
            $0.top.trailing.bottom.equalToSuperview().inset(2)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(checkmarkView)
            $0.leading.equalTo(logoImageView.snp.trailing).offset(10)
        }
        
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.equalTo(titleLabel)
        }
        
        addSubview(balanceLabel)
        balanceLabel.contentMode = .left
        balanceLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(checkmarkView.snp.leading).offset(-10)
        }
    }
}

@MainActor
private func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 17, weight: .regular)
    return label
}

@MainActor
private func makeSubtitleLabel() -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .caption1)
    label.contentMode = .left
    return label
}

@MainActor
private func makeCaptionLabel() -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12, weight: .regular)
    label.contentMode = .left
    label.textColor = .lightGray
    return label
}

@MainActor
private func makeAdditionalLabel() -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 17, weight: .regular)
    return label
}
