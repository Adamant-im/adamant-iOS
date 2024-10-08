//
//  RichTransactionStatusSubscription.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import Foundation
import CommonKit

final class TransactionStatusSubscription<StatusSubscriber: Subscriber>: Subscription, @unchecked Sendable where
    StatusSubscriber.Input == TransactionStatus,
    StatusSubscriber.Failure == Never {
    private let provider: WalletService
    private let transaction: CoinTransaction
    private let taskManager = TaskManager()
    private var subscriber: StatusSubscriber?
    
    @ObservableValue private var oldPendingAttempts: Int
    
    private var status: TransactionStatus {
        didSet { _ = subscriber?.receive(status) }
    }
    
    init(
        provider: WalletService,
        transaction: CoinTransaction,
        oldPendingAttempts: ObservableValue<Int>,
        subscriber: StatusSubscriber
    ) {
        self.provider = provider
        self.transaction = transaction
        self.subscriber = subscriber
        _oldPendingAttempts = oldPendingAttempts
        status = transaction.transactionStatus ?? .notInitiated
    }
    
    nonisolated func cancel() {
        reset()
    }
    
    nonisolated func request(_: Subscribers.Demand) {}
    
    func update() async {
        switch state {
        case .final:
            reset()
            return
        case .old:
            oldPendingAttempts += 1
        case .registered, .new:
            break
        }
        
        status = provider.statusWithFilters(
            transaction: transaction as? RichMessageTransaction,
            oldPendingAttempts: oldPendingAttempts,
            info: await provider.statusInfoFor(transaction: transaction)
        )
        
        Task { @Sendable in
            guard let interval = nextUpdateInterval else { return reset() }
            await Task.sleep(interval: interval)
            await update()
        }.stored(in: taskManager)
    }
}

private extension TransactionStatusSubscription {
    enum State {
        case new
        case old
        case registered
        case final
    }
    
    var state: State {
        switch status {
        case .inconsistent, .failed, .success, .noNetworkFinal:
            return .final
        case .registered:
            return .registered
        case .pending, .notInitiated, .noNetwork:
            guard let sentDate = transaction.dateValue else { return .final }
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
        switch state {
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
    
    func reset() {
        subscriber = nil
        taskManager.clean()
    }
}
