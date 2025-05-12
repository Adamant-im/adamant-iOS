import CommonKit
import MessageKit
//
//  NewMessagesCell.swift
//  Adamant
//
//  Created by Владимир Клевцов on 14.3.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import UIKit

final class NewMessagesCell: MessageReusableView {
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .adamant.chatSenderBackground
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.text = String.localized("chat.NewMessages")
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .adamant.active
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(separatorLine)
        addSubview(label)

        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let pixelSize = 2 / UIScreen.main.scale
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            separatorLine.topAnchor.constraint(equalTo: topAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: pixelSize),

            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            label.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 1)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
