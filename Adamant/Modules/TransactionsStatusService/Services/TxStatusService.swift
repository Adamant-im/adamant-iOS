//
//  TxStatusService.swift
//  Adamant
//
//  Created by Andrew G on 18.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import CoreData
import Combine

@TransactionsStatusActor
final class TxStatusService: TxStatusServiceProtocol {
    private let walletService: WalletService
    private let saveStatus: @TransactionsStatusActor (NSManagedObjectID, TransactionStatus) -> Void
    private let dismissService: @TransactionsStatusActor (AnyObject) -> Void
    
    private var originalTransaction: CoinTransaction?
    private var richTransactions: [String: RichMessageTransaction] = .init()
    private var status: TransactionStatus = .notInitiated
    private var oldPendingAttempts: Int = .zero
    private var txSentDate: Date?
    private var subscription: AnyCancellable?
    
    init(
        transaction: CoinTransaction,
        walletService: WalletService,
        saveStatus: @TransactionsStatusActor @escaping (NSManagedObjectID, TransactionStatus) -> Void,
        dismissService: @TransactionsStatusActor @escaping (AnyObject) -> Void
    ) {
        self.walletService = walletService
        self.saveStatus = saveStatus
        self.dismissService = dismissService
        configure(transaction: transaction)
    }
    
    func add(transaction: CoinTransaction) {
        if let transaction = transaction as? RichMessageTransaction {
            richTransactions[transaction.transactionId] = transaction
        } else {
            originalTransaction = transaction
        }
        
        saveStatuses()
    }
    
    func remove(transaction: CoinTransaction) {
        if let transaction = transaction as? RichMessageTransaction {
            richTransactions.removeValue(forKey: transaction.transactionId)
        } else if transaction.transactionId == originalTransaction?.transactionId {
            originalTransaction = transaction
        }
        
        if isEmpty {
            dismissService(self)
        } else {
            saveStatuses()
        }
    }
    
    func forceUpdate(transaction: CoinTransaction) async {
        status = .notInitiated
        saveStatuses()
        await updateStatus()
    }
}

private extension TxStatusService {
    enum StatusState {
        case new
        case old
        case registered
        case final
    }
    
    var isEmpty: Bool {
        richTransactions.isEmpty && originalTransaction == nil
    }
    
    var statusState: StatusState {
        switch status {
        case .inconsistent, .failed, .success:
            return .final
        case .registered:
            return .registered
        case .pending, .notInitiated:
            guard
                let sentDate = originalTransaction?.dateValue ?? validRichTransaction?.sentDate
            else { return .old }
            
            let sentInterval = Date.now.timeIntervalSince1970 - sentDate.timeIntervalSince1970
            
            let oldTxInterval = TimeInterval(
                walletService.core.newPendingInterval * .init(walletService.core.newPendingAttempts)
            )
            
            return sentInterval < oldTxInterval
                ? .new
                : .old
        }
    }
    
    var nextUpdateInterval: TimeInterval? {
        switch statusState {
        case .registered:
            walletService.core.registeredInterval
        case .new:
            walletService.core.newPendingInterval
        case .old:
            walletService.core.oldPendingInterval
        case .final:
            nil
        }
    }
    
    var richStatus: TransactionStatus {
        guard
            let transactionDate = txSentDate,
            let messageDate = validRichTransaction?.sentDate
        else { return status }
        
        let timeDifference = abs(transactionDate.timeIntervalSince(messageDate))
        return timeDifference <= walletService.core.consistencyMaxTime
            ? status
            : .inconsistent(.time)
    }
    
    var validRichTransactionId: String? {
        richTransactions.min { ($0.value.dateValue ?? .now) < ($1.value.dateValue ?? .now) }?.key
    }
    
    var validRichTransaction: RichMessageTransaction? {
        validRichTransactionId.flatMap { richTransactions[$0] }
    }
    
    var dubbedRichTransactions: [RichMessageTransaction] {
        guard let validRichTransactionId = validRichTransactionId else { return .init() }
        return richTransactions.values.filter { $0.transactionId != validRichTransactionId }
    }
    
    func updateStatus() async {
        guard let transaction = originalTransaction ?? validRichTransaction else { return }
        let info = await walletService.core.statusInfoFor(transaction: transaction)
        txSentDate = info.sentDate
        
        switch info.status {
        case .pending:
            status = oldPendingAttempts < walletService.core.oldPendingAttempts
                ? info.status
                : .failed
        case .success, .failed, .inconsistent, .registered, .notInitiated:
            status = info.status
        }
        
        saveStatuses()
    }
    
    func configure(transaction: CoinTransaction) {
        add(transaction: transaction)
        
        subscription = Task { [weak self] in
            while await self?.observationIteration() == true {
                try Task.checkCancellation()
            }
        }.eraseToAnyCancellable()
    }
    
    func saveStatuses() {
        if let originalTransaction {
            saveStatus(originalTransaction.objectID, status)
        }
        
        if let validRichTransaction {
            saveStatus(validRichTransaction.objectID, richStatus)
        }
        
        for tx in dubbedRichTransactions {
            saveStatus(tx.objectID, .inconsistent(.duplicate))
        }
    }
    
    /// Returns `false` if it's the last iteration. Otherwise it's `true`.
    func observationIteration() async -> Bool {
        await updateStatus()
        
        switch statusState {
        case .new, .registered:
            break
        case .old:
            oldPendingAttempts += 1
        case .final:
            return false
        }
        
        guard let interval = nextUpdateInterval else { return false }
        try? await Task.sleep(interval: interval)
        return true
    }
}
