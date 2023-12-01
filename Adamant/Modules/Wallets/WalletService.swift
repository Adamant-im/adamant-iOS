//
//  WalletService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.11.2023.
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

final class WalletService: WalletServiceProtocol {
    private let coreDataStack: CoreDataStack
    let core: WalletCoreProtocol

    init(core: WalletCoreProtocol, coreDataStack: CoreDataStack) {
        self.core = core
        self.coreDataStack = coreDataStack
    }
    
    func statusWithFilters(
        transaction: RichMessageTransaction?,
        oldPendingAttempts: Int,
        info: TransactionStatusInfo
    ) -> TransactionStatus {
        switch info.status {
        case .success:
            guard let transaction = transaction else {
                return info.status
            }
            return consistencyFilter(transaction: transaction, statusInfo: info)
                ? info.status
                : .inconsistent
        case .pending:
            return pendingAttemptsCountFilter(oldPendingAttempts: oldPendingAttempts, status: info.status)
                ? info.status
                : .failed
        case .noNetwork:
            return pendingAttemptsCountFilter(oldPendingAttempts: oldPendingAttempts, status: info.status)
                ? info.status
                : .noNetworkFinal
        case .failed, .inconsistent, .registered, .notInitiated, .noNetworkFinal:
            return info.status
        }
    }
    
    func statusInfoFor(transaction: CoinTransaction) async -> TransactionStatusInfo {
        await core.statusInfoFor(transaction: transaction)
    }
}

private extension WalletService {
    func pendingAttemptsCountFilter(oldPendingAttempts: Int, status: TransactionStatus) -> Bool {
        oldPendingAttempts < core.oldPendingAttempts
    }
    
    func consistencyFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> Bool {
        guard
            let transactionDate = statusInfo.sentDate,
            let messageDate = transaction.sentDate
        else { return false }
        
        let timeDifference = abs(transactionDate.timeIntervalSince(messageDate))
        
        return timeDifference <= core.consistencyMaxTime
    }
}

