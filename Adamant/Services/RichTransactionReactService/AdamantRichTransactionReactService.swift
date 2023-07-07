//
//  AdamantRichTransactionReactService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine

actor AdamantRichTransactionReactService: NSObject, RichTransactionReactService {
    private let coreDataStack: CoreDataStack
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    
    private lazy var richController = getRichTransactionsController()
    private lazy var transferController = getTransferController()
    private lazy var messageController = getMessageController()
    private let unknownErrorMessage = String.adamantLocalized.reply.shortUnknownMessageError
    
    private var reactions: [String: String] = [:]

    init(
        coreDataStack: CoreDataStack,
        apiService: ApiService,
        adamantCore: AdamantCore,
        accountService: AccountService
    ) {
        self.coreDataStack = coreDataStack
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
        super.init()
    }
    
    func startObserving() {
        richController.delegate = self
        try? richController.performFetch()
        richController.fetchedObjects?.forEach( update(transaction:) )
        
        transferController.delegate = self
        try? transferController.performFetch()
        transferController.fetchedObjects?.forEach( update(transaction:) )
        
        messageController.delegate = self
        try? messageController.performFetch()
        messageController.fetchedObjects?.forEach( update(transaction:) )
    }
}

extension AdamantRichTransactionReactService: NSFetchedResultsControllerDelegate {
    nonisolated func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type_: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        if let transaction = object as? RichMessageTransaction,
           transaction.isReact {
            Task { await processReactionCoreDataChange(type: type_, transaction: transaction) }
        }
        
        if let transaction = object as? RichMessageTransaction,
           !transaction.isReact {
            Task { await processCoreDataChange(type: type_, transaction: transaction) }
        }
        
        if let transaction = object as? TransferTransaction {
            Task { await processCoreDataChange(type: type_, transaction: transaction) }
        }
        
        if let transaction = object as? MessageTransaction {
            Task { await processCoreDataChange(type: type_, transaction: transaction) }
        }
    }
}

private extension AdamantRichTransactionReactService {
    func processReaction(transaction: RichMessageTransaction) {
        Task {
            guard
                let id = transaction.getRichValue(
                    for: RichContentKeys.react.reactto_id
                ),
                let reaction = transaction.getRichValue(
                    for: RichContentKeys.react.react_message
                )
            else {
                return
            }
            
            reactions[id] = reaction
            
            let baseTransaction = getTransactionFromDB(id: id)
            
            switch baseTransaction {
            case let trs as MessageTransaction:
                break
            case let trs as TransferTransaction:
                setReact(
                    to: transaction,
                    reaction: reaction
                )
            case let trs as RichMessageTransaction:
                setReact(
                    to: trs,
                    reaction: reaction
                )
            default:
                break
            }
        }
    }
    
    func update(transaction: RichMessageTransaction) {
        guard let reaction = reactions[transaction.transactionId],
              transaction.getRichValue(for: RichContentKeys.react.lastReaction) != reaction
        else { return }
        
        setReact(
            to: transaction,
            reaction: reaction
        )
    }
    
    func update(transaction: TransferTransaction) {
        guard let reaction = reactions[transaction.transactionId],
              transaction.lastReaction != reaction
        else { return }
        
        setReact(
            to: transaction,
            reaction: reaction
        )
    }
    
    func update(transaction: MessageTransaction) {
        if let reaction = reactions[transaction.transactionId] {
            print("to do add reactions to message")
        }
    }
    
    func setReact(
        to transaction: RichMessageTransaction,
        reaction: String
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? RichMessageTransaction
        transaction?.richContent?[RichContentKeys.react.lastReaction] = reaction
        try? privateContext.save()
    }
    
    func setReact(
        to transaction: TransferTransaction,
        reaction: String
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? TransferTransaction
        transaction?.lastReaction = reaction
        try? privateContext.save()
    }
}

// MARK: Core Data

private extension AdamantRichTransactionReactService {
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransactionFromDB(id: String) -> BaseTransaction? {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let request = NSFetchRequest<BaseTransaction>(entityName: "BaseTransaction")
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try privateContext.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    func processReactionCoreDataChange(type: NSFetchedResultsChangeType, transaction: RichMessageTransaction) {
        switch type {
        case .insert, .update:
            processReaction(transaction: transaction)
        case .delete:
            break
        case .move:
            break
        @unknown default:
            break
        }
    }
    
    func processCoreDataChange(type: NSFetchedResultsChangeType, transaction: AnyObject) {
        switch type {
        case .insert, .update:
            switch transaction {
            case let trs as MessageTransaction:
                update(transaction: trs)
            case let trs as TransferTransaction:
                update(transaction: trs)
            case let trs as RichMessageTransaction:
                update(transaction: trs)
            default:
                break
            }
        case .delete:
            break
        case .move:
            break
        @unknown default:
            break
        }
    }
    
    func getRichTransactionsController() -> NSFetchedResultsController<RichMessageTransaction> {
        let request: NSFetchRequest<RichMessageTransaction> = NSFetchRequest(
            entityName: RichMessageTransaction.entityName
        )

        request.sortDescriptors = []
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataStack.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    func getTransferController() -> NSFetchedResultsController<TransferTransaction> {
        let request: NSFetchRequest<TransferTransaction> = NSFetchRequest(
            entityName: TransferTransaction.entityName
        )

        request.sortDescriptors = []
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataStack.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    func getMessageController() -> NSFetchedResultsController<MessageTransaction> {
        let request: NSFetchRequest<MessageTransaction> = NSFetchRequest(
            entityName: MessageTransaction.entityName
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
