//
//  ChatState.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import CommonKit

public struct ChatState: Equatable {
    public var input: ChatInputBarModel
    public var items: [ChatItemModel]
    
    public static let `default` = Self(input: .default, items: .init())
}
