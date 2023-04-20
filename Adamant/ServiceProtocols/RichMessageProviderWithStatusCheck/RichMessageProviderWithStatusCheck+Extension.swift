//
//  RichMessageProviderWithStatusCheck+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension RichMessageProviderWithStatusCheck {
    func statusWithFilters(
        transaction: RichMessageTransaction,
        oldPendingAttempts: Int
    ) async -> TransactionStatus {
        let info = await statusInfoFor(transaction: transaction)
        
        switch info.status {
        case .success:
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
}

private extension RichMessageProviderWithStatusCheck {
    func pendingAttemptsCountFilter(oldPendingAttempts: Int, status: TransactionStatus) -> Bool {
        oldPendingAttempts < self.oldPendingAttempts
    }
    
    func consistencyFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> Bool {
        guard
            let transactionDate = statusInfo.sentDate,
            let messageDate = transaction.sentDate
        else { return false }
        
        let end = messageDate.addingTimeInterval(consistencyMaxTime)
        let dateRange = messageDate...end
        
        return dateRange.contains(transactionDate)
    }
}
