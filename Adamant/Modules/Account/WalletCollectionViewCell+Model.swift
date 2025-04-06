//
//  Model.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Parchment
import CommonKit
import UIKit

struct WalletCollectionViewCellModel {
    let index: Int
    let coinID: String
    let currencySymbol: String
    let currencyImage: UIImage
    let currencyNetwork: String
    var isBalanceInitialized: Bool
    var balance: Decimal?
    var notificationBadgeCount: Int
    
    static let `default` = WalletCollectionViewCellModel(
        index: 0,
        coinID: "",
        currencySymbol: "",
        currencyImage: UIImage(),
        currencyNetwork: "",
        isBalanceInitialized: false,
        balance: nil,
        notificationBadgeCount: 0
    )
}

// MARK: Comparable
extension WalletCollectionViewCellModel: Comparable {
    static func < (lhs: WalletCollectionViewCellModel, rhs: WalletCollectionViewCellModel) -> Bool {
        fatalError()
    }
}

// MARK: Hashable
extension WalletCollectionViewCellModel: Hashable {}
