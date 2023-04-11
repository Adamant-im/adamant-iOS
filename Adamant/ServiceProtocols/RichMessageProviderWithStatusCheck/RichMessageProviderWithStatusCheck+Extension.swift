//
//  RichMessageProviderWithStatusCheck+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension RichMessageProviderWithStatusCheck {
    func statusWithFilters(transaction: RichMessageTransaction) async -> TransactionStatus {
        let info = await statusInfoFor(transaction: transaction)
        
        switch info.status {
        case .success:
            return consistencyFilter(transaction: transaction, statusInfo: info)
                ? info.status
                : .inconsistent
        case .notInitiated, .pending:
            return timeFilter(transaction: transaction, statusInfo: info)
                ? info.status
                : .failed
        case .failed, .inconsistent, .registered:
            return info.status
        }
    }
}

private extension RichMessageProviderWithStatusCheck {
    func timeFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> Bool {
        guard let date = statusInfo.sentDate ?? transaction.sentDate else { return false }
        
        let timeAgo = -1 * date.timeIntervalSinceNow
        return timeAgo <= consistencyMaxTime
    }
    
    func consistencyFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> Bool {
        guard
            let transactionDate = statusInfo.sentDate,
            let messageDate = transaction.sentDate
        else { return false }
        
        let start = messageDate.addingTimeInterval(-60 * 5)
        let end = messageDate.addingTimeInterval(consistencyMaxTime)
        let dateRange = start...end
        
        return dateRange.contains(transactionDate)
    }
}
