//
//  ChatTransactionContainerView+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

extension ChatTransactionContainerView {
    struct Model: Equatable {
        let isFromCurrentSender: Bool
        let status: TransactionStatus
        let content: ChatTransactionContentView.Model
        
        static let `default` = Self(
            isFromCurrentSender: true,
            status: .notInitiated,
            content: .default
        )
    }
}
