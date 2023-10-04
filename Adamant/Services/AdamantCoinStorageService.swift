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
    
    private let coinId: String
    private let coreDataStack: CoreDataStack
    private lazy var transactionController = getTransactionController()

    @Published private var transactions: [CoinTransaction] = []

    var transactionsPublisher: Published<[CoinTransaction]>.Publisher {
        $transactions
    }
    
    // MARK: Init
    
    init(coinId: String, coreDataStack: CoreDataStack) {
        self.coinId = coinId
        self.coreDataStack = coreDataStack
        super.init()
        
        try? transactionController.performFetch()
        transactions = transactionController.fetchedObjects ?? []
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
                tx.transactionId == transaction.txId
            }
            let isLocalExist = coinTransactions.contains { tx in
                tx.transactionId == transaction.txId
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
            
            coinTransactions.append(coinTransaction)
        }
        
        try? privateContext.save()
        
        self.transactions.append(contentsOf: coinTransactions)
    }
    
    func updateStatus(for transactionId: String, status: TransactionStatus?) {
        let privateContext = coreDataStack.container.viewContext
        
        guard let transaction = getTransactionFromDB(
            id: transactionId,
            context: privateContext
        ) else { return }
        
        transaction.transactionStatus = status
        try? privateContext.save()
        
        guard let index = transactions.firstIndex(where: {
            $0.transactionId == transactionId
        }) else { return }
        
        transactions[index].transactionStatus = status
    }
}

private extension AdamantCoinStorageService {
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
