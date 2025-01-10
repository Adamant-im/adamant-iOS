//
//  UnspentTransaction+Equatable.swift
//  Adamant
//
//  Created by Christian Benua on 11.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BitcoinKit

extension UnspentTransaction: Equatable {
    public static func == (lhs: UnspentTransaction, rhs: UnspentTransaction) -> Bool {
        lhs.output == rhs.output &&
        lhs.outpoint == rhs.outpoint
    }
}
