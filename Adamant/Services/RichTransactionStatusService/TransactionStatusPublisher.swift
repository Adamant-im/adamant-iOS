//
//  RichTransactionStatusPublisher.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

struct TransactionStatusPublisher: Publisher {
    typealias Output = TransactionStatus
    typealias Failure = Never
    
    let provider: WalletService
    let transaction: CoinTransaction
    let oldPendingAttempts: ObservableValue<Int>
    
    func receive<S>(
        subscriber: S
    ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = TransactionStatusSubscription(
            provider: provider,
            transaction: transaction,
            oldPendingAttempts: oldPendingAttempts,
            subscriber: subscriber
        )
        
        subscriber.receive(subscription: subscription)
        Task { await subscription.update() }
    }
}
