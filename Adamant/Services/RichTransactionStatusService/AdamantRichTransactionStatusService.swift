//
//  AdamantRichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine

actor AdamantRichTransactionStatusService: NSObject, RichTransactionStatusService {
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    private let coreDataStack: CoreDataStack

    private lazy var controller = getRichTransactionsController()
    private var subscriptions = [String: AnyCancellable]()

    init(
        coreDataStack: CoreDataStack,
        richProviders: [String: RichMessageProviderWithStatusCheck]
    ) {
        self.coreDataStack = coreDataStack
        self.richProviders = richProviders
        super.init()
    }

    func forceUpdate(transaction: RichMessageTransaction) async {
        setStatus(for: transaction, status: .notInitiated)

        await setStatus(
            for: transaction,
            status: (try? getProvider(for: transaction)?.statusFor(transaction: transaction))
                ?? .pending
        )
    }
    
    func startObserving() {
        controller.delegate = self
        try? controller.performFetch()
        controller.fetchedObjects?.forEach(add(transaction:))
    }
}

extension AdamantRichTransactionStatusService: NSFetchedResultsControllerDelegate {
    nonisolated func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        guard let transaction = object as? RichMessageTransaction else { return }
        Task { await processCoreDataChange(type: type, transaction: transaction) }
    }
}

private extension AdamantRichTransactionStatusService {
    func add(transaction: RichMessageTransaction) {
        guard
            let id = transaction.transactionId,
            !subscriptions.keys.contains(id),
            let provider = getProvider(for: transaction)
        else { return }

        let publisher = RichTransactionStatusPublisher(
            provider: provider,
            transaction: transaction
        )

        setupSubscription(publisher: publisher, transaction: transaction)
    }

    func remove(transaction: RichMessageTransaction) {
        guard let id = transaction.transactionId else { return }
        subscriptions[id] = nil
    }

    func setupSubscription(publisher: RichTransactionStatusPublisher, transaction: RichMessageTransaction) {
        guard let id = transaction.transactionId else { return }
        
        subscriptions[id] = publisher.removeDuplicates().sink { status in
            Task { [weak self] in
                await self?.setStatus(for: transaction, status: status)
            }
        }
    }

    func getProvider(for transaction: RichMessageTransaction) -> RichMessageProviderWithStatusCheck? {
        guard let transfer = transaction.transfer else { return nil }
        return richProviders[transfer.type]
    }

    func setStatus(
        for transaction: RichMessageTransaction,
        status: TransactionStatus
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? RichMessageTransaction
        
        transaction?.transactionStatus = status
        try? privateContext.save()
    }

    // MARK: Core Data

    func processCoreDataChange(type: NSFetchedResultsChangeType, transaction: RichMessageTransaction) {
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
}
