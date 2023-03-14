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
        case new
        case old
        case registered
        case final
    }
    
    var state: State {
        switch status {
        case .inconsistent, .failed, .success:
            return .final
        case .registered:
            return .registered
        case .warning, .pending, .notInitiated, .updating, .none:
            let sentInterval = Date.now.timeIntervalSince1970
                - transaction.sentDate.timeIntervalSince1970
            
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
            guard oldPendingAttempts < provider.oldPendingAttempts else { return nil }
            return provider.oldPendingInterval
        case .final:
            return nil
        }
    }
    
    func update() async {
        switch state {
        case .final:
            return
        case .old:
            oldPendingAttempts += 1
        case .registered, .new:
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
