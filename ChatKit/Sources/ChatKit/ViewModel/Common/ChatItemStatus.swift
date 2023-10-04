//
//  ChatItemStatus.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

public enum ChatItemStatus: Equatable {
    case sent(blockchain: Bool)
    case received(blockchain: Bool)
    case pending
    case failed

    var isSentByPartner: Bool {
        switch self {
        case .received:
            return true
        case .sent, .pending, .failed:
            return false
        }
    }
}
