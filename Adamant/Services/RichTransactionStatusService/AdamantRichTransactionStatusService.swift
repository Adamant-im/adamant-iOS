//
//  AdamantRichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine
import CommonKit

actor AdamantRichTransactionStatusService: NSObject, RichTransactionStatusService {
    private let walletsManager: WalletServicesManager
    private let coreDataStack: CoreDataStack

    private lazy var controller = getRichTransactionsController()
    private var networkSubscription: AnyCancellable?
    private var subscriptions = [String: AnyCancellable]()
    private var oldPendingAttempts = [String: ObservableValue<Int>]()

    init(
        coreDataStack: CoreDataStack,
        walletsManager: WalletServicesManager
    ) {
        self.coreDataStack = coreDataStack
        self.walletsManager = walletsManager
        super.init()
        Task { await setupNetworkSubscription() }
    }

    func forceUpdate(transaction: RichMessageTransaction) async {
        setStatus(for: transaction, status: .notInitiated)
        
        guard
            let provider = await getProvider(for: transaction)
        else { return }

        let id = transaction.transactionId
        
        setStatus(
            for: transaction,
            status: provider.statusWithFilters(
                transaction: transaction,
                oldPendingAttempts: oldPendingAttempts[id]?.wrappedValue ?? .zero,
                info: await provider.statusInfoFor(transaction: transaction)
            )
        )
    }
    
    func startObserving() {
        controller.delegate = self
        try? controller.performFetch()
        controller.fetchedObjects?.forEach { tx in
            Task { await add(transaction: tx) }
        }
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
    func setupNetworkSubscription() {
        networkSubscription = NotificationCenter.default
            .publisher(for: .AdamantReachabilityMonitor.reachabilityChanged)
            .compactMap { $0.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool }
            .removeDuplicates()
            .asyncSink { [weak self] connected in
                guard connected else { return }
                await self?.reloadNoNetworkTransactions()
            }
    }
        
    func reloadNoNetworkTransactions() {
        let transactions = controller.fetchedObjects?.filter {
            switch $0.transactionStatus {
            case .noNetwork, .noNetworkFinal, .notInitiated:
                return true
            case .failed, .pending, .registered, .success, .inconsistent, .none:
                return false
            }
        }
        
        transactions?.compactMap { $0.transactionId }.forEach {
            oldPendingAttempts[$0] = .init(wrappedValue: .zero)
        }
        
        transactions?.forEach { transaction in
            setStatus(for: transaction, status: .noNetwork)
            Task { await add(transaction: transaction) }
        }
    }
    
    func add(transaction: RichMessageTransaction) async {
        guard
            let provider = await getProvider(for: transaction)
        else { return }
        
        let id = transaction.transactionId
        
        let oldPendingAttempts = oldPendingAttempts[id] ?? .init(wrappedValue: .zero)
        self.oldPendingAttempts[id] = oldPendingAttempts

        let publisher = RichTransactionStatusPublisher(
            provider: provider,
            transaction: transaction,
            oldPendingAttempts: oldPendingAttempts
        )
        
        subscriptions[id] = publisher.removeDuplicates().asyncSink { [weak self] status in
            await self?.setStatus(for: transaction, status: status)
        }
    }

    func remove(transaction: RichMessageTransaction) {
        let id = transaction.transactionId
        subscriptions[id] = nil
    }

    func getProvider(for transaction: RichMessageTransaction) async -> RichMessageProviderWithStatusCheck? {
        guard let transfer = transaction.transfer else { return nil }
        
        return await walletsManager.getService(richType: transfer.type) as? RichMessageProviderWithStatusCheck
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
            Task { await add(transaction: transaction) }
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
