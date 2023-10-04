//
//  ChatItemModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import Foundation

public enum ChatItemModel: Equatable {
    case loader
    case date(String)
    case message(ChatMessageModel)
    case transaction(ChatTransactionModel)
    
    var identifier: String {
        switch self {
        case .loader:
            return .empty
        case let .date(model):
            return model
        case let .message(model):
            return model.id
        case let .transaction(model):
            return model.id
        }
    }
}
