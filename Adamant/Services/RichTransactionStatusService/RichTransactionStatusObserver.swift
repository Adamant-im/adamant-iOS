//
//  RichTransactionStatusObserver.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

actor RichTransactionStatusObserver {
    private let provider: RichMessageProviderWithStatusCheck
    private var oldPendingAttempts: Int = .zero
    private var transaction: RichMessageTransaction
    
    @ObservableValue private(set) var status: TransactionStatus?
    
    init(provider: RichMessageProviderWithStatusCheck, transaction: RichMessageTransaction) {
        self.provider = provider
        self.transaction = transaction
        _status = .init(wrappedValue: transaction.transactionStatus)
        Task { await update() }
    }
}

private extension RichTransactionStatusObserver {
    enum State {
        case pending(isNew: Bool)
        case registered
    }
    
    var state: State {
        status?.isFinal == true
            ? .registered
            : .pending(
                isNew: Date.now.timeIntervalSince1970 - transaction.sentDate.timeIntervalSince1970
                    < .init(provider.newPendingInterval * .init(provider.newPendingAttempts))
            )
    }
    
    var nextUpdateInterval: TimeInterval? {
        switch state {
        case .registered:
            return provider.registeredInterval
        case .pending(isNew: true):
            return provider.newPendingInterval
        case .pending(isNew: false):
            guard oldPendingAttempts < provider.oldPendingAttempts else { return nil }
            return provider.oldPendingInterval
        }
    }
    
    func update() async {
        switch state {
        case .pending(isNew: false):
            oldPendingAttempts += 1
        case .pending(isNew: true), .registered:
            break
        }
        
        do {
            status = try await provider.statusFor(transaction: transaction)
        } catch {
            status = .pending
        }
        
        Task {
            guard let interval = nextUpdateInterval else { return }
            await Task.sleep(interval: interval)
            await update()
        }
    }
}
