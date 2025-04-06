//
//  ChatRefreshMock.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

final class ChatRefreshMock: UIRefreshControl {
    override init() {
        super.init()
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatRefreshMock {
    fileprivate func configure() {
        tintColor = .clear
        addTarget(self, action: #selector(endRefreshing), for: .valueChanged)
    }
}
