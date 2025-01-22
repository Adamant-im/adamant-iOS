//
//  TransactionsStatusService.swift
//  Adamant
//
//  Created by Andrew G on 18.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CoreData
import CommonKit

@TransactionsStatusActor
final class TransactionsStatusServiceCompose: NSObject, TransactionsStatusServiceComposeProtocol {
    private let coreDataStack: CoreDataStack
    private let walletServiceCompose: PublicWalletServiceCompose
    private lazy var controller = getRichTransactionsController()
    private var observers = [TransferIdentifier: TxStatusServiceProtocol]()
    
    nonisolated init(
        coreDataStack: CoreDataStack,
        walletServiceCompose: PublicWalletServiceCompose
    ) {
        self.coreDataStack = coreDataStack
        self.walletServiceCompose = walletServiceCompose
    }
    
    func forceUpdate(transaction: CoinTransaction) async {
        guard let transferIdentifier = transaction.transferIdentifier else { return }
        await observers[transferIdentifier]?.forceUpdate(transaction: transaction)
    }
    
    func startObserving() {
        controller.delegate = self
        try? controller.performFetch()
        
        controller.fetchedObjects?.forEach {
            add(transaction: $0)
        }
    }
}

extension TransactionsStatusServiceCompose: NSFetchedResultsControllerDelegate {
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

private extension TransactionsStatusServiceCompose {
    struct TransferIdentifier: Hashable {
        let transferHash: String
        let blockchain: String
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
    
    func add(transaction: CoinTransaction) {
        guard let transferIdentifier = transaction.transferIdentifier else { return }
        
        guard let observer = observers[transferIdentifier] else {
            return observers[transferIdentifier] = makeObserver(transaction: transaction)
        }
        
        observer.add(transaction: transaction)
    }
    
    func remove(transaction: CoinTransaction) {
        guard
            let transferIdentifier = transaction.transferIdentifier,
            let observer = observers[transferIdentifier]
        else { return }
        
        observer.remove(transaction: transaction)
    }
    
    func makeObserver(transaction: CoinTransaction) -> TxStatusServiceProtocol? {
        guard
            let walletService = walletServiceCompose.getWallet(by: transaction.blockchainType)
        else { return nil }
        
        return TxStatusService(
            transaction: transaction,
            walletService: walletService,
            saveStatus: { [weak self] in self?.saveStatus(objectID: $0, status: $1) },
            dismissService: { [weak self] in self?.dismissService($0)}
        )
    }
    
    func dismissService(_ service: AnyObject) {
        let key = observers.first { $0.value === service }?.key
        guard let key else { return }
        observers.removeValue(forKey: key)
    }
    
    func saveStatus(
        objectID: NSManagedObjectID,
        status: TransactionStatus
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        
        privateContext.parent = coreDataStack.container.viewContext
        let transaction = privateContext.object(with: objectID) as? CoinTransaction
        
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

private extension CoinTransaction {
    var transferIdentifier: TransactionsStatusServiceCompose.TransferIdentifier? {
        let hash = switch self {
        case let transaction as RichMessageTransaction:
            transaction.getRichValue(for: RichContentKeys.transfer.hash)
        default:
            txId
        }
        
        guard let hash else { return nil }
        return .init(transferHash: hash, blockchain: blockchainType)
    }
}
