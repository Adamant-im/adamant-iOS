//
//  RichTransactionStatusPublisher.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

struct RichTransactionStatusPublisher: Publisher {
    typealias Output = TransactionStatus
    typealias Failure = Never
    
    let provider: RichMessageProviderWithStatusCheck
    let transaction: RichMessageTransaction
    let oldPendingAttempts: ObservableValue<Int>
    
    func receive<S>(
        subscriber: S
    ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = RichTransactionStatusSubscription(
            provider: provider,
            transaction: transaction,
            oldPendingAttempts: oldPendingAttempts,
            subscriber: subscriber
        )
        
        subscriber.receive(subscription: subscription)
    }
}
