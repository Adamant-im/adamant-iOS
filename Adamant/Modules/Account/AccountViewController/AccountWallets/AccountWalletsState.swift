//
//  AccountWalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Parchment

struct AccountWalletsState: Equatable {
    var wallets: [AccountWalletCellState]
    
    static let `default` = Self(wallets: [])
}

struct AccountWalletCellState {
    @ObservableValue var model: WalletCollectionViewCellModel
    
    init(model: WalletCollectionViewCellModel) {
        self.model = model
    }
    
    static let `default` = Self(model: .default)
}

extension AccountWalletCellState: Equatable {
    static func == (lhs: AccountWalletCellState, rhs: AccountWalletCellState) -> Bool {
        lhs.model == rhs.model
    }
}

extension AccountWalletCellState: PagingItem{
    var identifier: Int { model.index }
    
    func isBefore(item: PagingItem) -> Bool {
        guard let other = item as? Self else { return false }
        return self.model.index < other.model.index
    }
    
    func isEqual(to item: PagingItem) -> Bool {
        guard let other = item as? Self else { return false }
        return self == other
    }
}
