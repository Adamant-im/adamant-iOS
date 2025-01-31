//
//  Model.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit
import Parchment

extension WalletCollectionViewCell {
    struct Model {
        let index: Int
        let coinID: String
        let currencySymbol: String
        let currencyImage: UIImage
        let currencyNetwork: String
        var isBalanceInitialized: Bool
        var balance: Decimal?
        var notificationBadgeCount: Int
        
        static let `default` = Model(
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
}

// MARK: PagingItem
extension WalletCollectionViewCell.Model: PagingItem {
    var identifier: Int { index }
    
    func isBefore(item: PagingItem) -> Bool {
        guard let other = item as? Self else { return false }
        return self.index < other.index
    }
    
    func isEqual(to item: PagingItem) -> Bool {
        guard let other = item as? Self else { return false }
        return self == other
    }
}

// MARK: Comparable
extension WalletCollectionViewCell.Model: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.index < rhs.index
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.index == rhs.index &&
        lhs.coinID == rhs.coinID &&
        lhs.currencySymbol == rhs.currencySymbol &&
        lhs.currencyNetwork == rhs.currencyNetwork &&
        lhs.isBalanceInitialized == rhs.isBalanceInitialized &&
        lhs.balance == rhs.balance &&
        lhs.notificationBadgeCount == rhs.notificationBadgeCount
    }
}

// MARK: Hashable
extension WalletCollectionViewCell.Model: Hashable {}
