//
//  AccountWalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Parchment
import Foundation

struct AccountWalletsState: Equatable {
    var wallets: [Page]
    
    static let `default` = Self(wallets: .init())
}

extension AccountWalletsState {
    struct Page: Equatable {
        var index: Int
        let coinID: String
        var balance: Decimal
        var address: String
        var notificationBadgeCount: Int
        
        static let `default` = Self(
            index: .zero,
            coinID: "",
            balance: 0,
            address: "",
            notificationBadgeCount: 0
        )
    }
}

extension AccountWalletsState.Page: PagingItem {
    var identifier: Int {
        return index
    }
    
    func isEqual(to item: any Parchment.PagingItem) -> Bool {
        return self == item as? Self
    }
    
    func isBefore(item: any Parchment.PagingItem) -> Bool {
        guard let other = item as? Self else { return false }
        return self.index < other.index
    }
}
