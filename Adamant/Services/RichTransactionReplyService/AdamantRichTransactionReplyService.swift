//
//  AdamantRichTransactionReplyService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreData
import Combine
import CommonKit

actor AdamantRichTransactionReplyService: NSObject, RichTransactionReplyService {
    private let coreDataStack: CoreDataStack
    private let apiService: AdamantApiServiceProtocol
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private let walletServiceCompose: PublicWalletServiceCompose
    
    private lazy var richController = getRichTransactionsController()
    private lazy var transferController = getTransferController()
    private let unknownErrorMessage = String.adamant.reply.shortUnknownMessageError

    init(
        coreDataStack: CoreDataStack,
        apiService: AdamantApiServiceProtocol,
        adamantCore: AdamantCore,
        accountService: AccountService,
        walletServiceCompose: PublicWalletServiceCompose
    ) {
        self.coreDataStack = coreDataStack
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
        self.walletServiceCompose = walletServiceCompose
        
        super.init()
    }
    
    func startObserving() {
        richController.delegate = self
        try? richController.performFetch()
        richController.fetchedObjects?.forEach( update(transaction:) )
        
        transferController.delegate = self
        try? transferController.performFetch()
        transferController.fetchedObjects?.forEach( update(transaction:) )
    }
}

extension AdamantRichTransactionReplyService: NSFetchedResultsControllerDelegate {
    nonisolated func controller(
        _: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at _: IndexPath?,
        for type_: NSFetchedResultsChangeType,
        newIndexPath _: IndexPath?
    ) {
        if let transaction = object as? RichMessageTransaction,
           transaction.additionalType == .reply {
            Task { await processCoreDataChange(type: type_, transaction: transaction) }
        }
        
        if let transaction = object as? TransferTransaction,
           transaction.replyToId != nil {
            Task { await processCoreDataChange(type: type_, transaction: transaction) }
        }
    }
}

private extension AdamantRichTransactionReplyService {
    func update(transaction: TransferTransaction) {
        Task {
            do {
                guard let id = transaction.replyToId,
                      transaction.decodedReplyMessage == nil
                else { return }
                
                let message = try await getReplyMessage(from: id)
                
                setReplyMessage(
                    for: transaction,
                    message: message
                )
            } catch {
                setReplyMessage(
                    for: transaction,
                    message: unknownErrorMessage
                )
            }
        }
    }
    
    func update(transaction: RichMessageTransaction) {
        Task {
            do {
                guard let id = transaction.getRichValue(for: RichContentKeys.reply.replyToId),
                      transaction.getRichValue(for: RichContentKeys.reply.decodedReplyMessage) == nil
                else { return }
                
                let message = try await getReplyMessage(from: id)
                
                setReplyMessage(
                    for: transaction,
                    message: message
                )
            } catch {
                setReplyMessage(
                    for: transaction,
                    message: unknownErrorMessage
                )
            }
        }
    }
    
    func getReplyMessage(from id: String) async throws -> String {
        if let baseTransaction = getTransactionFromDB(id: id) {
            return try getReplyMessage(from: baseTransaction)
        }
        
        let transactionReply = try await getTransactionFromAPI(by: UInt64(id) ?? 0)
        return try getReplyMessage(from: transactionReply)
    }
    
    func getTransactionFromAPI(by id: UInt64) async throws -> Transaction {
        try await apiService.getTransaction(id: id, withAsset: true).get()
    }
    
    func getReplyMessage(from transaction: Transaction) throws -> String {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey
        else {
            throw ApiServiceError.accountNotFound
        }
        
        let isOut = transaction.senderId == address
        
        let publicKey: String? = isOut
        ? transaction.recipientPublicKey
        : transaction.senderPublicKey
        
        let transactionStatus = isOut
        ? String.adamant.chat.transactionSent
        : String.adamant.chat.transactionReceived
        
        guard let chat = transaction.asset.chat else {
            let message = "\(transactionStatus) \(AdmWalletService.currencySymbol) \(transaction.amount)"
            return message
        }
        
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
               transaction.amount > 0 {
                let commentContent = (richContent[RichContentKeys.reply.replyMessage] as? String) ?? ""
                let comment = !commentContent.isEmpty
                ? ": \(commentContent)"
                : ""
                
                let humanType = AdmWalletService.currencySymbol
                
                message = "\(transactionStatus) \(transaction.amount) \(humanType)\(comment)"
                break
            }
            
            if let data = decodedMessage.data(using: String.Encoding.utf8),
               let richContent = RichMessageTools.richContent(from: data),
               let transfer = RichMessageTransfer(content: richContent) {
                let comment = !transfer.comments.isEmpty
                ? ": \(transfer.comments)"
                : ""
                
                let humanType = walletServiceCompose.getWallet(
                    by: transfer.type
                )?.core.tokenSymbol ?? transfer.type
                
                message = "\(transactionStatus) \(transfer.amount) \(humanType)\(comment)"
                break
            }
            
            if let data = decodedMessage.data(using: String.Encoding.utf8),
               let richContent = RichMessageTools.richContent(from: data),
               let replyMessage = richContent[RichContentKeys.reply.replyMessage] as? String {
                
                message = replyMessage
                break
            }
            
            if let data = decodedMessage.data(using: String.Encoding.utf8),
               let richContent = RichMessageTools.richContent(from: data),
               let replyMessage = richContent[RichContentKeys.reply.replyMessage] as? [String: Any],
               replyMessage[RichContentKeys.file.files] is [[String: Any]] {
                message = FilePresentationHelper.getFilePresentationText(richContent)
                break
            }
            
            if let data = decodedMessage.data(using: String.Encoding.utf8),
               let richContent = RichMessageTools.richContent(from: data),
               richContent[RichContentKeys.file.files] is [[String: Any]] {
                message = FilePresentationHelper.getFilePresentationText(richContent)
                break
            }
            
            message = decodedMessage
        }
        
        return MessageProcessHelper.process(message)
    }
    
    func getReplyMessage(from transaction: BaseTransaction) throws -> String {
        guard let address = accountService.account?.address else {
            throw ApiServiceError.accountNotFound
        }
        
        let isOut = transaction.senderId == address
        
        let transactionStatus = isOut
        ? String.adamant.chat.transactionSent
        : String.adamant.chat.transactionReceived
        
        var message: String
        
        switch transaction {
        case let trs as MessageTransaction:
            message = trs.message ?? ""
        case let trs as TransferTransaction:
            let trsComment = trs.comment ?? ""
            let comment = !trsComment.isEmpty
            ? ": \(trsComment)"
            : ""
            
            message = "\(transactionStatus) \(trs.amount ?? 0.0) \(AdmWalletService.currencySymbol)\(comment)"
        case let trs as RichMessageTransaction:
            if let replyMessage = trs.getRichValue(for: RichContentKeys.reply.replyMessage) {
                message = replyMessage
                break
            }
            
            if let richContent = trs.richContent,
               let transfer = RichMessageTransfer(content: richContent) {
                let comment = !transfer.comments.isEmpty
                ? ": \(transfer.comments)"
                : ""
                
                let humanType = walletServiceCompose.getWallet(
                    by: transfer.type
                )?.core.tokenSymbol ?? transfer.type
                
                message = "\(transactionStatus) \(transfer.amount) \(humanType)\(comment)"
                break
            }
            
            if let richContent = trs.richContent,
               let _: [[String: Any]] = trs.getRichValue(for: RichContentKeys.file.files) {
                message = FilePresentationHelper.getFilePresentationText(richContent)
                break
            }
            
            message = unknownErrorMessage
        default:
            message = unknownErrorMessage
        }
        
        return MessageProcessHelper.process(message)
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
        transaction?.richContent?[RichContentKeys.reply.decodedReplyMessage] = message
        try? privateContext.save()
    }
    
    func setReplyMessage(
        for transaction: TransferTransaction,
        message: String
    ) {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let transaction = privateContext.object(with: transaction.objectID)
            as? TransferTransaction
        transaction?.decodedReplyMessage = message
        try? privateContext.save()
    }
}

// MARK: Core Data

private extension AdamantRichTransactionReplyService {
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransactionFromDB(id: String) -> BaseTransaction? {
        let privateContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )

        privateContext.parent = coreDataStack.container.viewContext
        
        let request = NSFetchRequest<BaseTransaction>(entityName: "BaseTransaction")
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try privateContext.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    func processCoreDataChange(type: NSFetchedResultsChangeType, transaction: TransferTransaction) {
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
    
    func getTransferController() -> NSFetchedResultsController<TransferTransaction> {
        let request: NSFetchRequest<TransferTransaction> = NSFetchRequest(
            entityName: TransferTransaction.entityName
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
