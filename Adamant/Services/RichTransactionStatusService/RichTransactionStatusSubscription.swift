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

actor RichTransactionStatusSubscription<StatusSubscriber: Subscriber>: Subscription where
    StatusSubscriber.Input == TransactionStatus,
    StatusSubscriber.Failure == Never
{
    private let provider: RichMessageProviderWithStatusCheck
    private let transaction: RichMessageTransaction
    private let taskManager = TaskManager()
    private var subscriber: StatusSubscriber?
    
    @ObservableValue private var oldPendingAttempts: Int
    
    private var status: TransactionStatus {
        didSet { _ = subscriber?.receive(status) }
    }
    
    init(
        provider: RichMessageProviderWithStatusCheck,
        transaction: RichMessageTransaction,
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
        Task { await reset() }
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
        
        status = await provider.statusWithFilters(
            transaction: transaction,
            oldPendingAttempts: oldPendingAttempts,
            info: await provider.statusInfoFor(transaction: transaction)
        )
        
        Task {
            guard let interval = nextUpdateInterval else { return reset() }
            await Task.sleep(interval: interval)
            await update()
        }.stored(in: taskManager)
    }
}

private extension RichTransactionStatusSubscription {
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
            guard let sentDate = transaction.sentDate else { return .final }
            let sentInterval = Date.now.timeIntervalSince1970 - sentDate.timeIntervalSince1970
            
            let oldTxInterval = TimeInterval(
                provider.newPendingInterval * .init(provider.newPendingAttempts)
            )
            
            return sentInterval < oldTxInterval
                ? .new
                : .old
        }
    }
    
    var nextUpdateInterval: TimeInterval? {
        switch state {
        case .registered:
            return provider.registeredInterval
        case .new:
            return provider.newPendingInterval
        case .old:
            return provider.oldPendingInterval
        case .final:
            return nil
        }
    }
    
    func reset() {
        subscriber = nil
        taskManager.clean()
    }
}
