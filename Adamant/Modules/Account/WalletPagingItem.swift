//
//  WalletPagingItem.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Parchment

class WalletPagingItem: PagingItem, Hashable, Comparable {
    let index: Int
    let currencySymbol: String
    let currencyImage: UIImage
    let currencyNetwork: String
    let isBalanceInitialized: Bool
    
    var balance: Decimal?
    var notifications: Int = 0
    
    init(
        index: Int,
        currencySymbol symbol: String,
        currencyImage image: UIImage,
        isBalanceInitialized: Bool?,
        currencyNetwork network: String = ""
    ) {
        self.index = index
        self.isBalanceInitialized = isBalanceInitialized ?? false
        self.currencySymbol = symbol
        self.currencyImage = image
        self.currencyNetwork = network
    }
    
    // MARK: Hashable, Comparable
    var hashValue: Int {
        return index.hashValue &+ currencySymbol.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(currencySymbol)
    }
    
    static func < (lhs: WalletPagingItem, rhs: WalletPagingItem) -> Bool {
        return lhs.index < rhs.index
    }
    
    static func == (lhs: WalletPagingItem, rhs: WalletPagingItem) -> Bool {
        return lhs.index == rhs.index &&
                lhs.currencySymbol == rhs.currencySymbol
    }
}
