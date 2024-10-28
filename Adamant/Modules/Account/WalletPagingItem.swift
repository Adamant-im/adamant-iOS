//
//  WalletPagingItem.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Parchment
import CommonKit
import Combine

struct WalletItem: Equatable {
    var index: Int
    var currencySymbol: String
    var currencyImage: UIImage
    var currencyNetwork: String
    var isBalanceInitialized: Bool
    var balance: Decimal?
    var notifications: Int = 0
    
    init(
        index: Int,
        currencySymbol symbol: String,
        currencyImage image: UIImage,
        isBalanceInitialized: Bool?,
        currencyNetwork network: String = .empty,
        balance: Decimal? = nil
    ) {
        self.index = index
        self.isBalanceInitialized = isBalanceInitialized ?? false
        self.currencySymbol = symbol
        self.currencyImage = image
        self.currencyNetwork = network
        self.balance = balance
    }
    
    static let `default` = Self(
        index: .zero,
        currencySymbol: .empty,
        currencyImage: .init(),
        isBalanceInitialized: nil
    )
}

final class WalletItemModel: ObservableObject, PagingItem, Hashable, Comparable, @unchecked Sendable {
    @Published var model: WalletItem = .default
    
    init(model: WalletItem) {
        self.model = model
    }
    
    // MARK: Hashable, Comparable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(model.index)
        hasher.combine(model.currencySymbol)
    }
    
    static func < (lhs: WalletItemModel, rhs: WalletItemModel) -> Bool {
        lhs.model.index < rhs.model.index
    }
    
    static func == (lhs: WalletItemModel, rhs: WalletItemModel) -> Bool {
        lhs.model.index == rhs.model.index &&
        lhs.model.currencySymbol == rhs.model.currencySymbol
    }
}
