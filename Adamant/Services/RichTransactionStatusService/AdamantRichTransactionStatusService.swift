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
    private lazy var controller = getRichTransactionsController()
    private var observers = [RichMessageTransaction: RichTransactionStatusObserver]()
    private var subscriptions = [RichMessageTransaction: AnyCancellable]()
    private var coreDataStack: CoreDataStack
    
    init(
        coreDataStack: CoreDataStack,
        richProviders: [String: RichMessageProviderWithStatusCheck]
    ) {
        self.coreDataStack = coreDataStack
        self.richProviders = richProviders
        super.init()
        
        Task {
            await controller.delegate = self
            try await controller.performFetch()
        }
    }
    
    func forceUpdate(transaction: RichMessageTransaction) async {
        setStatus(for: transaction, status: .notInitiated)
        
        await setStatus(
            for: transaction,
            status: (try? getProvider(for: transaction)?.statusFor(transaction: transaction))
                ?? .pending
        )
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
        
        Task {
            switch type {
            case .insert:
                await add(transaction: transaction)
            case .delete:
                await remove(transaction: transaction)
            case .update, .move:
                break
            @unknown default:
                break
            }
        }
    }
}

private extension AdamantRichTransactionStatusService {
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
    
    func add(transaction: RichMessageTransaction) {
        guard
            !observers.keys.contains(where: { $0.txId == transaction.txId }),
            let provider = getProvider(for: transaction)
        else { return }
        
        let observer = RichTransactionStatusObserver(
            provider: provider,
            transaction: transaction
        )
        
        observers[transaction] = observer
        Task { await setupSubscription(observer: observer, transaction: transaction) }
    }
    
    func remove(transaction: RichMessageTransaction) {
        observers[transaction] = nil
        subscriptions[transaction] = nil
    }
    
    func setupSubscription(
        observer: RichTransactionStatusObserver,
        transaction: RichMessageTransaction
    ) async {
        subscriptions[transaction] = await observer.$status
            .removeDuplicates()
            .sink { status in
                Task { [weak self] in
                    guard let status = status else { return }
                    await self?.setStatus(for: transaction, status: status)
                }
            }
    }
    
    func setStatus(
        for transaction: RichMessageTransaction,
        status: TransactionStatus
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        
        privateContext.parent = coreDataStack.container.viewContext
        transaction.transactionStatus = status
        try? privateContext.save()
    }
    
    func getProvider(
        for transaction: RichMessageTransaction
    ) -> RichMessageProviderWithStatusCheck? {
        guard let transfer = transaction.transfer else { return nil }
        return richProviders[transfer.type]
    }
}
