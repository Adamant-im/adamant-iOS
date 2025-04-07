//
//  NotificationWarningView.swift
//
//
//  Created by Andrey Golubenko on 19.07.2023.
//

import SnapKit
import UIKit

public final class NotificationWarningView: UIView {
    public var emoji: Emoji? = .allCases.randomElement() {
        didSet { update() }
    }

    public var message: String = .empty {
        didSet { update() }
    }

    private lazy var emojiLabel = UILabel(font: .systemFont(ofSize: 75))
    private lazy var messageLabel = UILabel()

    private lazy var verticalStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [emojiLabel, messageLabel])
        view.axis = .vertical
        view.spacing = 10
        view.alignment = .center
        return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}

extension NotificationWarningView {
    public enum Emoji: String, CaseIterable {
        case 😔, 😟, 😭, 😰, 😨, 🤭, 😯, 😣, 😖, 🤕
    }
}

extension NotificationWarningView {
    fileprivate func setup() {
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview().inset(20)
        }
    }

    fileprivate func update() {
        emojiLabel.text = emoji?.rawValue
        messageLabel.text = message
    }
}
