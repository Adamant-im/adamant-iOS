//
//  AdamantTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import CoreData
import Combine

actor AdamantTransactionStatusService: NSObject, TransactionStatusService {
    private let coreDataStack: CoreDataStack
    private let walletServiceCompose: WalletServiceCompose
    
    private lazy var controller = getRichTransactionsController()
    private var transfers = [RichTransferIdentifier: RichTransferData]()
    
    init(
        coreDataStack: CoreDataStack,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.coreDataStack = coreDataStack
        self.walletServiceCompose = walletServiceCompose
    }
    
    func forceUpdate(transaction: CoinTransaction) async {
        guard
            let transaction = transaction as? RichMessageTransaction,
            let id = transaction.richTransferIdentifier,
            let provider = transfers[id]?.provider
        else { return }
        
        transfers[id]?.status = .notInitiated
        saveStatus(id: id)
        
        transfers[id]?.status = provider.statusWithFilters(
            transaction: transaction,
            oldPendingAttempts: transfers[id]?.oldPendingAttempts ?? .zero,
            // TODO: waits for connectivity
            info: await provider.statusInfoFor(transaction: transaction)
        )
        
        saveStatus(id: id)
    }
    
    func startObserving() {
        controller.delegate = self
        try? controller.performFetch()
        controller.fetchedObjects?.forEach(add(transaction:))
    }
}

extension AdamantTransactionStatusService: NSFetchedResultsControllerDelegate {
    nonisolated func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        guard let transaction = object as? CoinTransaction else { return }
        Task { await processCoreDataChange(type: type, transaction: transaction) }
    }
}

private extension AdamantTransactionStatusService {
    struct RichTransferIdentifier: Hashable {
        let transferHash: String
        let blockchain: String
    }

    final class RichTransferData {
        let provider: WalletService
        var status: TransactionStatus
        var transactions: [String: RichMessageTransaction]
        var oldPendingAttempts: Int
        var subscription: AnyCancellable?
        
        init(
            provider: WalletService,
            status: TransactionStatus,
            transactions: [String: RichMessageTransaction],
            oldPendingAttempts: Int,
            subscription: AnyCancellable? = nil
        ) {
            self.provider = provider
            self.status = status
            self.transactions = transactions
            self.oldPendingAttempts = oldPendingAttempts
            self.subscription = subscription
        }
    }

    enum TransactionStatusState {
        case new
        case old
        case registered
        case final
    }
    
    func observeStatus(id: RichTransferIdentifier) async throws {
        while
            transfers[id]?.statusState != .final,
            let transaction = transfers[id]?.validTransaction,
            let oldPendingAttempts = transfers[id]?.oldPendingAttempts,
            let provider = transfers[id]?.provider
        {
            try Task.checkCancellation()
            let newStatus = provider.statusWithFilters(
                transaction: transaction,
                oldPendingAttempts: oldPendingAttempts,
                // TODO: waits for connectivity
                info: await provider.statusInfoFor(transaction: transaction)
            )
            
            try Task.checkCancellation()
            transfers[id]?.status = newStatus
            saveStatus(id: id)
            
            switch transfers[id]?.statusState {
            case .registered, .new:
                break
            case .old:
                transfers[id]?.oldPendingAttempts += 1
            case .final, .none:
                return
            }
            
            guard let interval = transfers[id]?.nextUpdateInterval else { return }
            await Task.sleep(interval: interval)
        }
    }
    
    func remove(transaction: CoinTransaction) {
        guard
            let transaction = transaction as? RichMessageTransaction,
            let id = transaction.richTransferIdentifier
        else { return }
        
        transfers[id]?.transactions.removeValue(forKey: transaction.transactionId)
        guard transfers[id]?.transactions.isEmpty == true else { return }
        transfers[id]?.subscription?.cancel()
        transfers.removeValue(forKey: id)
    }
    
    func add(transaction: CoinTransaction) {
        guard
            let transaction = transaction as? RichMessageTransaction,
            let id = transaction.richTransferIdentifier,
            let provider = walletServiceCompose.getWallet(by: id.blockchain)
        else { return }
        
        defer { saveStatus(id: id) }
        
        guard !transfers.keys.contains(id) else {
            transfers[id]?.transactions[transaction.transactionId] = transaction
            return
        }
        
        transfers[id] = .init(
            provider: provider,
            status: .notInitiated,
            transactions: [transaction.transactionId: transaction],
            oldPendingAttempts: .zero
        )
        
        transfers[id]?.subscription = Task {
            try await observeStatus(id: id)
        }.eraseToAnyCancellable()
    }
    
    func processCoreDataChange(type: NSFetchedResultsChangeType, transaction: CoinTransaction) {
        switch type {
        case .insert, .update:
            add(transaction: transaction)
        case .delete:
            remove(transaction: transaction)
        case .move:
            break
        @unknown default:
            break
        }
    }
    
    func saveStatus(id: RichTransferIdentifier) {
        guard let transferData = transfers[id] else { return }
        
        if let validTransaction = transferData.validTransaction {
            saveStatus(transaction: validTransaction, status: transferData.status)
        }
        
        transferData.inconsistentTransactions.forEach {
            saveStatus(transaction: $0, status: .inconsistent(.duplicate))
        }
    }
    
    func saveStatus(
        transaction: CoinTransaction,
        status: TransactionStatus
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? CoinTransaction
        
        guard let transaction = transaction else { return }
        transaction.transactionStatus = status
        try? privateContext.save()
    }
    
    func getRichTransactionsController() -> NSFetchedResultsController<CoinTransaction> {
        let request: NSFetchRequest<CoinTransaction> = NSFetchRequest(
            entityName: CoinTransaction.entityCoinName
        )

        request.sortDescriptors = []
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataStack.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
}

private extension RichMessageTransaction {
    var richTransferIdentifier: AdamantTransactionStatusService.RichTransferIdentifier? {
        guard let hash = transfer?.hash else { return nil }
        
        return .init(
            transferHash: hash,
            blockchain: blockchainType
        )
    }
}

private extension AdamantTransactionStatusService.RichTransferData {
    var validTransactionId: String? {
        transactions.min { ($0.value.dateValue ?? .now) < ($1.value.dateValue ?? .now) }?.key
    }
    
    var validTransaction: RichMessageTransaction? {
        validTransactionId.flatMap { transactions[$0] }
    }
    
    var inconsistentTransactions: [RichMessageTransaction] {
        guard let validTransactionId = validTransactionId else { return .init() }
        var keys = Set(transactions.keys)
        keys.remove(validTransactionId)
        return keys.compactMap { transactions[$0] }
    }
    
    var statusState: AdamantTransactionStatusService.TransactionStatusState {
        switch status {
        case .inconsistent, .failed, .success:
            return .final
        case .registered:
            return .registered
        case .pending, .notInitiated:
            guard let sentDate = validTransaction?.sentDate else { return .final }
            let sentInterval = Date.now.timeIntervalSince1970 - sentDate.timeIntervalSince1970
            
            let oldTxInterval = TimeInterval(
                provider.core.newPendingInterval * .init(provider.core.newPendingAttempts)
            )
            
            return sentInterval < oldTxInterval
                ? .new
                : .old
        }
    }
    
    var nextUpdateInterval: TimeInterval? {
        switch statusState {
        case .registered:
            return provider.core.registeredInterval
        case .new:
            return provider.core.newPendingInterval
        case .old:
            return provider.core.oldPendingInterval
        case .final:
            return nil
        }
    }
}
