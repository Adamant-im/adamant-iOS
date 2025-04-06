//
//  MessageModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

protocol MessageModel: Sendable {
    var id: String { get }

    func makeReplyContent() -> NSAttributedString
}
