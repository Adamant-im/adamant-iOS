//
//  AdamantRichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData

actor AdamantRichTransactionStatusService: RichTransactionStatusService {
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    private var updatingTransactions = Set<RichMessageTransaction>()
    
    init(richProviders: [String: RichMessageProviderWithStatusCheck]) {
        self.richProviders = richProviders
    }
    
    func update(
        _ transaction: RichMessageTransaction,
        parentContext: NSManagedObjectContext,
        resetBeforeUpdate: Bool
    ) async throws {
        if resetBeforeUpdate {
            setStatus(for: transaction, status: .notInitiated, parentContext: parentContext)
        }
        
        guard !updatingTransactions.contains(transaction) else { return }
        updatingTransactions.insert(transaction)
        
//        Сообщения-отчёты об отправленных средствах создаются раньше,
//        чем на эфирных нодах появляется сама транзакция перевода (по ТЗ).
//        Проблема - как только сообщение появляется в чате,
//        мы запрашиваем у эфирной ноды статус транзакции,
//        которую ещё не отправили - нода возвращает ошибку.
//        Решение - если сообщение появилось только что,
//        обновим статус этой транзакции с 'некоторой' задержкой. 🤷🏻‍♂️
        
        if transaction.isJustCreated {
            try await Task.sleep(interval: 5)
        }
        
        guard let status = try await getStatus(for: transaction) else { return }
        setStatus(for: transaction, status: status, parentContext: parentContext)
        updatingTransactions.remove(transaction)
    }
}

private extension AdamantRichTransactionStatusService {
    func getStatus(for transaction: RichMessageTransaction) async throws -> TransactionStatus? {
        guard
            let transfer = transaction.transfer,
            let provider = richProviders[transfer.type]
        else { return nil }
        
        return try await withUnsafeThrowingContinuation { completion in
            provider.statusFor(transaction: transaction) { result in
                switch result {
                case let .success(status):
                    completion.resume(returning: status)
                case let .failure(error):
                    completion.resume(throwing: error)
                }
            }
        }
    }
    
    func setStatus(
        for transaction: RichMessageTransaction,
        status: TransactionStatus,
        parentContext: NSManagedObjectContext
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        
        privateContext.parent = parentContext
        transaction.transactionStatus = status
        try? privateContext.save()
    }
}

private extension ChatTransaction {
    var isJustCreated: Bool {
        guard let date = date else { return false }
        return date.timeIntervalSinceNow > -2
    }
}
