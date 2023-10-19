//
//  AdamantTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine
import CommonKit

actor AdamantTransactionStatusService: NSObject, TransactionStatusService {
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    private let coreDataStack: CoreDataStack

    private lazy var controller = getRichTransactionsController()
    private var networkSubscription: AnyCancellable?
    private var subscriptions = [String: AnyCancellable]()
    private var oldPendingAttempts = [String: ObservableValue<Int>]()

    init(
        coreDataStack: CoreDataStack,
        richProviders: [String: RichMessageProviderWithStatusCheck]
    ) {
        self.coreDataStack = coreDataStack
        self.richProviders = richProviders
        super.init()
        Task { await setupNetworkSubscription() }
    }

    func forceUpdate(transaction: CoinTransaction) async {
        setStatus(for: transaction, status: .notInitiated)
        
        guard
            let provider = getProvider(for: transaction)
        else { return }

        let id = transaction.transactionId
        
        setStatus(
            for: transaction,
            status: provider.statusWithFilters(
                transaction: transaction as? RichMessageTransaction,
                oldPendingAttempts: oldPendingAttempts[id]?.wrappedValue ?? .zero,
                info: await provider.statusInfoFor(transaction: transaction)
            )
        )
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
    func setupNetworkSubscription() {
        networkSubscription = NotificationCenter.default
            .publisher(for: .AdamantReachabilityMonitor.reachabilityChanged)
            .compactMap { $0.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool }
            .removeDuplicates()
            .sink { connected in
                guard connected else { return }
                Task { [weak self] in await self?.reloadNoNetworkTransactions() }
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
            add(transaction: transaction)
        }
    }
    
    func add(transaction: CoinTransaction) {
        guard
            let provider = getProvider(for: transaction),
            transaction.transactionStatus != .success
        else { return }
        
        let id = transaction.transactionId
        
        let oldPendingAttempts = oldPendingAttempts[id] ?? .init(wrappedValue: .zero)
        self.oldPendingAttempts[id] = oldPendingAttempts

        let publisher = TransactionStatusPublisher(
            provider: provider,
            transaction: transaction,
            oldPendingAttempts: oldPendingAttempts
        )
        
        subscriptions[id] = publisher.removeDuplicates().sink { status in
            Task { [weak self] in
                await self?.setStatus(for: transaction, status: status)
            }
        }
    }

    func remove(transaction: CoinTransaction) {
        let id = transaction.transactionId
        subscriptions[id] = nil
    }

    func getProvider(for transaction: CoinTransaction) -> RichMessageProviderWithStatusCheck? {
        return richProviders[transaction.blockchainType]
    }

    func setStatus(
        for transaction: CoinTransaction,
        status: TransactionStatus
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? CoinTransaction
        
        guard let transaction = transaction else {
            return
        }
        
        transaction.transactionStatus = status
        try? privateContext.save()
    }

    // MARK: Core Data

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
