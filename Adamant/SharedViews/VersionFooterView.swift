//
//  VersionFooterView.swift
//  Adamant
//
//  Created by Andrew G on 19.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class VersionFooterView: UIView {
    struct Model {
        let version: String
        let commit: String?
        
        static let `default` = Self(version: .empty, commit: nil)
    }
    
    var model: Model = .default {
        didSet { update() }
    }
    
    private let versionLabel = UILabel(
        font: .adamantPrimary(ofSize: fontSize),
        textColor: .adamant.primary
    )
    
    private let commitLabel = UILabel(
        font: .adamantPrimary(ofSize: fontSize),
        textColor: .adamant.primary
    )
    
    private lazy var labelsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [versionLabel])
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = labelsGap
        return stack
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.addSubview(labelsStack)
        labelsStack.snp.makeConstraints {
            $0.directionalHorizontalEdges.top.equalToSuperview()
            $0.bottom.equalToSuperview().inset(bottomInset)
        }
        
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
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        .init(
            width: size.width,
            height: containerView.systemLayoutSizeFitting(size).height
        )
    }
}

private extension VersionFooterView {
    func configure() {
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func update() {
        versionLabel.text = model.version
        commitLabel.text = model.commit
        
        switch (model.commit, commitLabel.superview) {
        case (.some, .none):
            labelsStack.addArrangedSubview(commitLabel)
        case (.none, .some):
            labelsStack.removeArrangedSubview(commitLabel)
        case (.none, .none), (.some, .some):
            break
        }
    }
}

private let fontSize: CGFloat = 17
private let labelsGap: CGFloat = 6
private let bottomInset: CGFloat = 15
