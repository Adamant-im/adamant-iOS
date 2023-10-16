//
//  ChatReactionsStackModel.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import Foundation

public struct ChatReactionsStackModel: Equatable {
    public let first: ChatReactionModel?
    public let second: ChatReactionModel?
    
    public static let `default` = Self(first: nil, second: nil)
    
    public init(first: ChatReactionModel?, second: ChatReactionModel?) {
        self.first = first
        self.second = second
    }
}

extension ChatReactionsStackModel {
    var isEmpty: Bool {
        first == nil && second == nil
    }
}
