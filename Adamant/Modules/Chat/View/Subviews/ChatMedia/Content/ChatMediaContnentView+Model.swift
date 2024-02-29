//
//  ChatMediaContnentView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension ChatMediaContentView {
    struct Model: Equatable {
        let id: String
        var files: [ChatFile]
        var isHidden: Bool
        let isFromCurrentSender: Bool
        
        static let `default` = Self(
            id: "",
            files: [],
            isHidden: false,
            isFromCurrentSender: false
        )
    }
}
