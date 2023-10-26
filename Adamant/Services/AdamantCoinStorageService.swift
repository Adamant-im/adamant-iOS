//
//  AdamantCoinStorageService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 26.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CoreData
import Combine
import CommonKit

final class AdamantCoinStorageService: NSObject, CoinStorageService {
    
    // MARK: Proprieties
    
    private let blockchainType: String
    private let coinId: String
    private let coreDataStack: CoreDataStack
    private lazy var transactionController = getTransactionController()
    private var subscriptions = Set<AnyCancellable>()
    
    @ObservableValue private var transactions: [TransactionDetails] = []

    var transactionsPublisher: any Observable<[TransactionDetails]> {
        $transactions
    }
    
    // MARK: Init
    
    init(coinId: String, coreDataStack: CoreDataStack, blockchainType: String) {
        self.coinId = coinId
        self.coreDataStack = coreDataStack
        self.blockchainType = blockchainType
        super.init()
        
        try? transactionController.performFetch()
        transactions = transactionController.fetchedObjects ?? []
        
        setupObserver()
    }
    
    func append(_ transaction: TransactionDetails) {
        append([transaction])
    }
    
    func append(_ transactions: [TransactionDetails]) {
        let privateContext = coreDataStack.container.viewContext
        privateContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        
        var coinTransactions: [CoinTransaction] = []
        
        transactions.forEach { transaction in
            let isExist = self.transactions.contains { tx in
                tx.txId == transaction.txId
            }
            let isLocalExist = coinTransactions.contains { tx in
                tx.txId == transaction.txId
            }
            guard !isExist, !isLocalExist else { return }
            
            let coinTransaction = CoinTransaction(context: privateContext)
            coinTransaction.amount = NSDecimalNumber(decimal: transaction.amountValue ?? 0)
            coinTransaction.date = (transaction.dateValue ?? Date()) as NSDate
            coinTransaction.recipientId = transaction.recipientAddress
            coinTransaction.senderId = transaction.senderAddress
            coinTransaction.isOutgoing = transaction.isOutgoing
            coinTransaction.coinId = coinId
            coinTransaction.transactionId = transaction.txId
            coinTransaction.transactionStatus = transaction.transactionStatus
            coinTransaction.blockchainType = blockchainType
            
            coinTransactions.append(coinTransaction)
        }
        
        try? privateContext.save()
    }
    
    func updateStatus(for transactionId: String, status: TransactionStatus?) {
        let privateContext = coreDataStack.container.viewContext
        
        guard let transaction = getTransactionFromDB(
            id: transactionId,
            context: privateContext
        ) else { return }
        
        transaction.transactionStatus = status
        try? privateContext.save()
    }
    
    func clear() {
        transactions = []
    }
}

private extension AdamantCoinStorageService {
    func setupObserver() {
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: coreDataStack.container.viewContext
        )
        .sink { [weak self] notification in
            let changes = notification.managedObjectContextChanges(of: CoinTransaction.self)

            if let inserted = changes.inserted, !inserted.isEmpty {
                let filteredInserted: [TransactionDetails] = inserted.filter {
                    $0.coinId == self?.coinId
                }
                self?.transactions.append(contentsOf: filteredInserted)
            }
            
            if let updated = changes.updated, !updated.isEmpty {
                let filteredUpdated = updated.filter { $0.coinId == self?.coinId }
                
                filteredUpdated.forEach { coinTransaction in
                    guard let index = self?.transactions.firstIndex(where: {
                        $0.txId == coinTransaction.txId
                    })
                    else { return }
                    
                    self?.transactions[index] = coinTransaction
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func getTransactionController() -> NSFetchedResultsController<CoinTransaction> {
        let request: NSFetchRequest<CoinTransaction> = NSFetchRequest(
            entityName: CoinTransaction.entityCoinName
        )
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "coinId = %@", coinId)
        ])
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true),
            NSSortDescriptor(key: "transactionId", ascending: true)
        ]
        
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataStack.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransactionFromDB(id: String, context: NSManagedObjectContext) -> CoinTransaction? {
        let request = NSFetchRequest<CoinTransaction>(entityName: CoinTransaction.entityCoinName)
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
}

struct ManagedObjectContextChanges<Object: NSManagedObject> {
    var updated: Set<Object>?
    var inserted: Set<Object>?
    var deleted: Set<Object>?
}

extension Notification {
    func managedObjectContextChanges<Object: NSManagedObject>(of type: Object.Type) -> ManagedObjectContextChanges<Object> {
        return ManagedObjectContextChanges<Object>(
            updated: objects(forKey: NSUpdatedObjectsKey),
            inserted: objects(forKey: NSInsertedObjectsKey),
            deleted: objects(forKey: NSDeletedObjectsKey))
    }
    
    private func objects<Object: NSManagedObject>(forKey key: String) -> Set<Object>? {
        guard let userInfo = userInfo else {
            assertionFailure()
            return nil
        }
        let objects = (userInfo[key] as? Set<NSManagedObject>) ?? []
        return Set(objects.compactMap { $0 as? Object })
    }
}
