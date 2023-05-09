//
//  AdamantChatTransactionService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 06.10.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MarkdownKit

actor AdamantChatTransactionService: ChatTransactionService {
    
    // MARK: Dependencies
    
    private let adamantCore: AdamantCore
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    
    private let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    // MARK: Lifecycle
    
    init(adamantCore: AdamantCore, accountService: AccountService) {
        self.adamantCore = adamantCore
        
        var richProviders = [String: RichMessageProviderWithStatusCheck]()
        for case let provider as RichMessageProviderWithStatusCheck in accountService.wallets {
            richProviders[provider.dynamicRichMessageType] = provider
        }
        self.richProviders = richProviders
    }
    
    /// Make operations serial
    func addOperations(_ op: Operation) {
        queue.addOperation(op)
    }
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransfer(id: String, context: NSManagedObjectContext) -> TransferTransaction? {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    /// Parse raw transaction into CoreData chat transaction
    ///
    /// - Parameters:
    ///   - transaction: Raw transaction
    ///   - isOutgoing: is outgoing
    ///   - publicKey: account public key
    ///   - partner: partner account
    ///   - removedMessages: removed messages to hide them
    ///   - privateKey: logged account private key
    ///   - context: context to insert parsed transaction to
    /// - Returns: New parsed transaction
    func chatTransaction(from transaction: Transaction, isOutgoing: Bool, publicKey: String, privateKey: String, partner: BaseAccount, removedMessages: [String], context: NSManagedObjectContext) -> ChatTransaction? {
        let messageTransaction: ChatTransaction
        guard let chat = transaction.asset.chat else {
            if transaction.type == .send {
                messageTransaction = transferTransaction(from: transaction, isOut: isOutgoing, partner: partner, context: context)
                return messageTransaction
            }
            return nil
        }
        
        // MARK: Decode message, message must contain data
        if let decodedMessage = adamantCore.decodeMessage(rawMessage: chat.message, rawNonce: chat.ownMessage, senderPublicKey: publicKey, privateKey: privateKey)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if (decodedMessage.isEmpty && transaction.amount > 0) || !decodedMessage.isEmpty {
                switch chat.type {
                // MARK: Text message
                case .message, .messageOld, .signal, .unknown:
                    if transaction.amount > 0 {
                        if let trs = getTransfer(id: String(transaction.id), context: context) {
                            messageTransaction = trs
                        } else {
                            let trs = TransferTransaction(entity: TransferTransaction.entity(), insertInto: context)
                            trs.comment = decodedMessage
                            messageTransaction = trs
                        }
                    } else {
                        let trs = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
                        trs.message = decodedMessage
                        messageTransaction = trs
                        
                        let markdown = markdownParser.parse(decodedMessage)
                        
                        trs.isMarkdown = markdown.length != decodedMessage.count
                    }
                    
                // MARK: Rich message
                case .richMessage:
                    if let data = decodedMessage.data(using: String.Encoding.utf8),
                       let richContent = RichMessageTools.richContent(from: data),
                       let type = richContent[RichContentKeys.type] as? String,
                       type != RichContentKeys.reply.reply,
                       richContent[RichContentKeys.reply.replyToId] == nil {
                        let trs = RichMessageTransaction(
                            entity: RichMessageTransaction.entity(),
                            insertInto: context
                        )
                        
                        trs.richContent = richContent
                        trs.richType = type
                        trs.isReply = false
                        trs.transactionStatus = richProviders[type] != nil ? .notInitiated : nil
                        messageTransaction = trs
                        
                        break
                    }
                    
                    if let data = decodedMessage.data(using: String.Encoding.utf8),
                       let richContent = RichMessageTools.richContent(from: data),
                       richContent[RichContentKeys.reply.replyToId] != nil,
                       transaction.amount > 0 {
                        
                        let trs: TransferTransaction
                        
                        if let trsDB = getTransfer(
                            id: String(transaction.id),
                            context: context
                        ) {
                            trs = trsDB
                        } else {
                            trs = TransferTransaction(
                                entity: TransferTransaction.entity(),
                                insertInto: context
                            )
                        }
                        
                        trs.comment = richContent[RichContentKeys.reply.replyMessage] as? String
                        trs.replyToId = richContent[RichContentKeys.reply.replyToId] as? String
                        
                        messageTransaction = trs
                        print("find adm rich, id=\(trs.replyToId), com = \(trs.comment)")
                        break
                    }
                        
                    if let data = decodedMessage.data(using: String.Encoding.utf8),
                       let richContent = RichMessageTools.richContent(from: data),
                       richContent[RichContentKeys.reply.replyToId] != nil,
                       transaction.amount <= 0 {
                        let trs = RichMessageTransaction(
                            entity: RichMessageTransaction.entity(),
                            insertInto: context
                        )
                        let transferContent = richContent[RichContentKeys.reply.replyMessage] as? [String: String]
                        let type = (transferContent?[RichContentKeys.type] as? String) ?? RichContentKeys.reply.reply
                        
                        trs.richContent = richContent
                        trs.richType = type
                        trs.isReply = true
                        trs.transactionStatus = richProviders[type] != nil ? .notInitiated : nil
                        messageTransaction = trs
                        
                        break
                    }
                    
                    let trs = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
                    trs.message = decodedMessage
                    messageTransaction = trs
                }
            } else {
                let trs = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
                trs.message = ""
                trs.isHidden = true
                messageTransaction = trs
            }
        }
        // MARK: Failed to decode, or message was empty
        else {
            let trs = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
            trs.message = ""
            trs.isHidden = true
            messageTransaction = trs
        }
        
        messageTransaction.amount = transaction.amount as NSDecimalNumber
        messageTransaction.date = transaction.date as NSDate
        messageTransaction.recipientId = transaction.recipientId
        messageTransaction.senderId = transaction.senderId
        messageTransaction.transactionId = String(transaction.id)
        messageTransaction.type = Int16(chat.type.rawValue)
        messageTransaction.height = Int64(transaction.height)
        messageTransaction.isConfirmed = true
        messageTransaction.isOutgoing = isOutgoing
        messageTransaction.blockId = transaction.blockId
        messageTransaction.confirmations = transaction.confirmations
        messageTransaction.chatMessageId = String(transaction.id)
        messageTransaction.fee = transaction.fee as NSDecimalNumber
        messageTransaction.statusEnum = MessageStatus.delivered
        messageTransaction.partner = partner
        
        let transactionId = messageTransaction.transactionId
        messageTransaction.isHidden = removedMessages.contains(transactionId)
        
        return messageTransaction
    }
    
    func transferTransaction(
        from transaction: Transaction,
        isOut: Bool,
        partner: BaseAccount?,
        context: NSManagedObjectContext
    ) -> TransferTransaction {
        let transfer: TransferTransaction
        if let trs = getTransfer(id: String(transaction.id), context: context) {
            transfer = trs
            transfer.confirmations = transaction.confirmations
            transfer.statusEnum = .delivered
            transfer.blockId = transaction.blockId
        } else {
            transfer = TransferTransaction(context: context)
            transfer.amount = transaction.amount as NSDecimalNumber
            transfer.date = transaction.date as NSDate
            transfer.recipientId = transaction.recipientId
            transfer.senderId = transaction.senderId
            transfer.transactionId = String(transaction.id)
            transfer.type = Int16(TransactionType.chatMessage.rawValue)
            transfer.showsChatroom = true
            transfer.height = Int64(transaction.height)
            transfer.isConfirmed = true
            transfer.isOutgoing = isOut
            transfer.blockId = transaction.blockId
            transfer.confirmations = transaction.confirmations
            transfer.chatMessageId = String(transaction.id)
            transfer.fee = transaction.fee as NSDecimalNumber
            transfer.statusEnum = MessageStatus.delivered
            transfer.partner = partner
        }
        
        transfer.isOutgoing = isOut
        transfer.partner = partner
        return transfer
    }
}
