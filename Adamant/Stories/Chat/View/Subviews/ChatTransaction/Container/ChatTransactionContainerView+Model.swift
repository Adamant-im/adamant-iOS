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
        var status: TransactionStatus
        let updateStatusAction: ComparableAction?
        
        static let `default` = Self(
            isFromCurrentSender: true,
            content: .default,
            status: .notInitiated,
            updateStatusAction: .init(action: {})
        )
    }
}
