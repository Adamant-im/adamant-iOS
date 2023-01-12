//
//  ChatTransactionContentView+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatTransactionContentView {
    struct Model: Equatable {
        let title: String
        let icon: UIImage
        let amount: String
        let currency: String
        let date: String
        let comment: String?
        let backgroundColor: UIColor
        
        static let `default` = Self(
            title: "",
            icon: .init(),
            amount: "",
            currency: "",
            date: .init(),
            comment: nil,
            backgroundColor: .clear
        )
    }
}
