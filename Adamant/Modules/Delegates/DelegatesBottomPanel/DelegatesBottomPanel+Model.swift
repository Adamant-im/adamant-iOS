//
//  DelegatesBottomPanel+Model.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension DelegatesBottomPanel {
    struct Model {
        let upvotes: Int
        let downvotes: Int
        let new: (Int, Int)
        let total: (Int, Int)
        let cost: String
        let isSendingEnabled: Bool
        let newVotesColor: UIColor
        let totalVotesColor: UIColor
        let sendAction: () -> Void
        
        static var `default`: Self {
            Self(
                upvotes: .zero,
                downvotes: .zero,
                new: (.zero, .zero),
                total: (.zero, .zero),
                cost: "",
                isSendingEnabled: false,
                newVotesColor: .adamant.textColor,
                totalVotesColor: .adamant.textColor,
                sendAction: {}
            )
        }
    }
}
