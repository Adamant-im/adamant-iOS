//
//  WalletService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CoreData

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
        case .pending:
            return pendingAttemptsCountFilter(oldPendingAttempts: oldPendingAttempts, status: info.status)
                ? info.status
                : .failed
        case .failed, .inconsistent, .registered, .notInitiated:
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
    
    func consistencyFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> TransactionStatus {
        let consistencyTimeFilter = consistencyTimeFilter(transaction: transaction, statusInfo: statusInfo)
        let consistencyDuplicateFilter = consistencyDuplicateFilter(transaction: transaction)
        
        if !consistencyTimeFilter {
            return .inconsistent(.time)
        }
        
        if !consistencyDuplicateFilter {
            return .inconsistent(.duplicate)
        }
        return statusInfo.status
    }
    
    func consistencyTimeFilter(transaction: RichMessageTransaction, statusInfo: TransactionStatusInfo) -> Bool {
        guard
            let transactionDate = statusInfo.sentDate,
            let messageDate = transaction.sentDate
        else { return false }
        
        let timeDifference = abs(transactionDate.timeIntervalSince(messageDate))
        
        return timeDifference <= core.consistencyMaxTime
    }
    
    func consistencyDuplicateFilter(transaction: RichMessageTransaction) -> Bool {
        guard let hash = transaction.transfer?.hash else { return false }
        
        let allTransactions = getAllRichTransactionsFromDB(with: hash).sorted(
            by: { ($0.dateValue ?? Date()) < ($1.dateValue ?? Date()) }
        )
        
        guard allTransactions.count > 1 else { return true }
        
        return allTransactions.first?.txId == transaction.txId
    }
}

extension WalletService {
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getAllRichTransactionsFromDB(with id: String) -> [RichMessageTransaction] {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = coreDataStack.container.viewContext
        
        let request = NSFetchRequest<RichMessageTransaction>(entityName: RichMessageTransaction.entityName)
        request.predicate = NSPredicate(format: "richTransferHash == %@", String(id))
        
        do {
            let result = try context.fetch(request)
            return result
        } catch {
            return []
        }
    }
}
