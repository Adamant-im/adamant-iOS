//
//  ChatTransactionContainerView+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension ChatTransactionContainerView {
    struct Model: Equatable {
        let isFromCurrentSender: Bool
        let content: ChatTransactionContentView.Model
        let status: Status?
        
        static let `default` = Self(
            isFromCurrentSender: true,
            content: .default,
            status: nil
        )
    }
}

extension ChatTransactionContainerView.Model {
    final class Status: Equatable {
        let id: String
        @Published private(set) var status: TransactionStatus = .notInitiated
        
        init(id: String, status: AnyObservable<TransactionStatus>) {
            self.id = id
            status.assign(to: &$status)
        }
        
        static func ==(lhs: Status, rhs: Status) -> Bool {
            lhs.id == rhs.id
        }
    }
}
