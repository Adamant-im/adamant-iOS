//
//  WalletServiceProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 05.12.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol WalletServiceProtocol {
    func statusWithFilters(
        transaction: RichMessageTransaction?,
        oldPendingAttempts: Int,
        info: TransactionStatusInfo
    ) -> TransactionStatus
    
    func statusInfoFor(transaction: CoinTransaction) async -> TransactionStatusInfo
}
