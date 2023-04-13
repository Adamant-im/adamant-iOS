//
//  AdamantRichTransactionReplyService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine

actor AdamantRichTransactionReplyService: NSObject, RichTransactionReplyService {
    private let coreDataStack: CoreDataStack
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private var richMessageProvider: [String: RichMessageProvider] = [:]
    
    private lazy var controller = getRichTransactionsController()
    private let unknownErrorMessage = "UNKNOWN"

    init(
        coreDataStack: CoreDataStack,
        apiService: ApiService,
        adamantCore: AdamantCore,
        accountService: AccountService
    ) {
        self.coreDataStack = coreDataStack
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
        super.init()
        
        self.richMessageProvider = self.makeRichMessageProviders()
    }
    
    func startObserving() {
        controller.delegate = self
        try? controller.performFetch()
        controller.fetchedObjects?.forEach( update(transaction:) )
    }
    
    func makeRichMessageProviders() -> [String: RichMessageProvider] {
        .init(
            uniqueKeysWithValues: accountService
                .wallets
                .compactMap { $0 as? RichMessageProvider }
                .map { ($0.dynamicRichMessageType, $0) }
        )
    }
}

extension AdamantRichTransactionReplyService: NSFetchedResultsControllerDelegate {
    nonisolated func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        guard let transaction = object as? RichMessageTransaction,
              transaction.isReply
        else {
            return
        }
        
        Task { await processCoreDataChange(type: type, transaction: transaction) }
    }
}

private extension AdamantRichTransactionReplyService {
    func update(transaction: RichMessageTransaction) {
        Task {
            guard let id = transaction.richContent?[RichContentKeys.reply.replyToId],
                  transaction.richContent?[RichContentKeys.reply.decodedMessage] == nil
            else { return }
            
            do {
                let message = try await getReplyMessage(by: UInt64(id) ?? 0)
                print("reply message decoded =\(message); id=\(id)")
                
                setReplyMessage(for: transaction, message: message)
            } catch {
                print("error= \(error)")
            }
        }
    }
    
    func getReplyMessage(by id: UInt64) async throws -> String {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey
        else {
            throw ApiServiceError.accountNotFound
        }
        
        let transaction = try await apiService.getTransaction(id: id, withAsset: true)
        
        guard let chat = transaction.asset.chat else {
            let message = "\(AdmWalletService.currencySymbol) \(transaction.amount)"
            return message
        }

        let isOut = transaction.senderId == address
        
        let publicKey: String? = isOut
        ? transaction.recipientPublicKey
        : transaction.senderPublicKey
        
        let transactionStatus = isOut
        ? String.adamantLocalized.chat.transactionSent
        : String.adamantLocalized.chat.transactionReceived
        
        guard let publicKey = publicKey else { return unknownErrorMessage }
        
        let decodedMessage = adamantCore.decodeMessage(
            rawMessage: chat.message,
            rawNonce: chat.ownMessage,
            senderPublicKey: publicKey,
            privateKey: privateKey
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let decodedMessage = decodedMessage else { return unknownErrorMessage }
        
        var message: String
        
        switch chat.type {
        case .message, .messageOld, .signal, .unknown:
            let comment = !decodedMessage.isEmpty
            ? ": \(decodedMessage)"
            : ""
            
            message = transaction.amount > 0
            ? "\(transactionStatus) \(transaction.amount) \(AdmWalletService.currencySymbol)\(comment)"
            : decodedMessage
            
        case .richMessage:
            if let data = decodedMessage.data(using: String.Encoding.utf8),
               let richContent = RichMessageTools.richContent(from: data),
               let type = richContent[RichContentKeys.type],
               let transfer = RichMessageTransfer(content: richContent) {
                let comment = !transfer.comments.isEmpty
                ? ": \(transfer.comments)"
                : ""
                let humanType = richMessageProvider[transfer.type]?.tokenSymbol ?? transfer.type
                
                message = "\(transactionStatus) \(transfer.amount) \(humanType)\(comment)"
            } else if let data = decodedMessage.data(using: String.Encoding.utf8),
                      let richContent = RichMessageTools.richContent(from: data),
                      let replyMessage = richContent[RichContentKeys.reply.replyMessage] {
                
                message = replyMessage
            } else {
                message = decodedMessage
            }
        }
        
        return message
    }

    func setReplyMessage(
        for transaction: RichMessageTransaction,
        message: String
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? RichMessageTransaction
        transaction?.richContent?[RichContentKeys.reply.decodedMessage] = message
        try? privateContext.save()
    }

    // MARK: Core Data

    func processCoreDataChange(type: NSFetchedResultsChangeType, transaction: RichMessageTransaction) {
        switch type {
        case .insert, .update:
            update(transaction: transaction)
        case .delete:
            break
        case .move:
            break
        @unknown default:
            break
        }
    }
    
    func getRichTransactionsController() -> NSFetchedResultsController<RichMessageTransaction> {
        let request: NSFetchRequest<RichMessageTransaction> = NSFetchRequest(
            entityName: RichMessageTransaction.entityName
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
