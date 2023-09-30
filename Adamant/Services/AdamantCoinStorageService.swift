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
    
    @ObservableValue private(set) var transactions: [CoinTransaction] = []
    
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
            let coinTransaction = CoinTransaction(context: privateContext)
            coinTransaction.amount = NSDecimalNumber(decimal: transaction.amountValue ?? 0)
            coinTransaction.date = transaction.dateValue as? NSDate
            coinTransaction.recipientId = transaction.recipientAddress
            coinTransaction.senderId = transaction.senderAddress
            coinTransaction.isOutgoing = transaction.isOutgoing
            coinTransaction.coinId = coinId
            coinTransaction.transactionId = transaction.txId
            
            coinTransactions.append(coinTransaction)
        }
        
        try? privateContext.save()
        
        self.transactions.append(contentsOf: coinTransactions)
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
}
