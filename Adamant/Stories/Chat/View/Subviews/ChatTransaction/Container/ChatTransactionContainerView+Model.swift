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
        let id: String
        let isFromCurrentSender: Bool
        let content: ChatTransactionContentView.Model
        var status: TransactionStatus
        
        static let `default` = Self(
            id: "",
            isFromCurrentSender: true,
            content: .default,
            status: .notInitiated
        )
    }
}
