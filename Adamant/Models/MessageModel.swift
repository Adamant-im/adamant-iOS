//
//  MessageModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol MessageModel {
    var id: String { get }
    var isFromCurrentSender: Bool { get }
    
    func makeReplyContent() -> NSAttributedString
}
