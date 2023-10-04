//
//  ChatMessagesState.swift
//  Adamant
//
//  Created by Andrew G on 09.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import ChatKit

struct ChatMessagesState: Equatable {
    var messages: [ChatItemModel]
    var isInitialLoading: Bool
    
    static let `default` = Self(
        messages: .init(),
        isInitialLoading: false
    )
}
