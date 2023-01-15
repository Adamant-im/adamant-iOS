//
//  AdamantRichTransactionStatusService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData

final class AdamantRichTransactionStatusService: RichTransactionStatusService {
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    private var updatingTransactions = Set<RichMessageTransaction>()
    private let updateQueue = DispatchQueue(label: "im.adamant.richTransactionsStatusUpdate")
    
    init(richProviders: [String: RichMessageProviderWithStatusCheck]) {
        self.richProviders = richProviders
    }
    
    func update(_ transaction: RichMessageTransaction, parentContext: NSManagedObjectContext) {
        guard !updatingTransactions.contains(transaction) else { return }
        updatingTransactions.insert(transaction)
        
        let updateAction = { [weak self] in
            self?.getStatus(for: transaction) { status in
                self?.setStatus(for: transaction, status: status, parentContext: parentContext)
                self?.updatingTransactions.remove(transaction)
            }
        }
        
//        Сообщения-отчёты об отправленных средствах создаются раньше,
//        чем на эфирных нодах появляется сама транзакция перевода (по ТЗ).
//        Проблема - как только сообщение появляется в чате,
//        мы запрашиваем у эфирной ноды статус транзакции,
//        которую ещё не отправили - нода возвращает ошибку.
//        Решение - если сообщение появилось только что,
//        обновим статус этой транзакции с 'некоторой' задержкой. 🤷🏻‍♂️
        
        let delay: TimeInterval = transaction.isJustCreated
            ? 5
            : .zero
        
        updateQueue.asyncAfter(deadline: .now() + delay) { updateAction() }
    }
}

private extension AdamantRichTransactionStatusService {
    func getStatus(
        for transaction: RichMessageTransaction,
        completion: @escaping (TransactionStatus) -> Void
    ) {
        guard
            let transfer = transaction.transfer,
            let provider = richProviders[transfer.type]
        else { return }
        
        provider.statusFor(transaction: transaction) { result in
            switch result {
            case let .success(status):
                completion(status)
            case .failure:
                completion(.failed)
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
