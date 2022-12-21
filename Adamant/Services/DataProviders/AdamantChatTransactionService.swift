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

class AdamantChatTransactionService: ChatTransactionService {
    
    // MARK: Dependencies
    var adamantCore: AdamantCore!
    var richProviders: [String:RichMessageProviderWithStatusCheck]!
    
    private let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    private var transactionInProgress: [UInt64] = []
    private var onTransactionSaved: (() -> Void)?
    private let processSemaphore = DispatchSemaphore(value: 0)
    private var waitSemaphoreCount = 0
    
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
                        let type = richContent[RichContentKeys.type] {
                        let trs = RichMessageTransaction(entity: RichMessageTransaction.entity(), insertInto: context)
                        trs.richContent = richContent
                        trs.richType = type
                        trs.transactionStatus = richProviders[type] != nil ? .notInitiated : nil
                        messageTransaction = trs
                    } else {
                        let trs = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
                        trs.message = decodedMessage
                        messageTransaction = trs
                    }
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
        messageTransaction.chatMessageId = UUID().uuidString
        messageTransaction.fee = transaction.fee as NSDecimalNumber
        messageTransaction.statusEnum = MessageStatus.delivered
        messageTransaction.partner = partner
        
        if let transactionId = messageTransaction.transactionId {
            messageTransaction.isHidden = removedMessages.contains(transactionId)
        }
        
        return messageTransaction
    }
    
    func transferTransaction(from transaction: Transaction, isOut: Bool, partner: BaseAccount?, context: NSManagedObjectContext) -> TransferTransaction {
        let transfer: TransferTransaction
        if let trs = getTransfer(id: String(transaction.id), context: context) {
            transfer = trs
            transfer.confirmations = transaction.confirmations
            transfer.statusEnum = .delivered
            transfer.blockId = transaction.blockId
        } else if transactionInProgress.contains(transaction.id) {
            waitSemaphoreCount += 1
            processSemaphore.wait()
            return transferTransaction(from: transaction, isOut: isOut, partner: partner, context: context)
        } else {
            transactionInProgress.append(transaction.id)
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
            transfer.chatMessageId = UUID().uuidString
            transfer.fee = transaction.fee as NSDecimalNumber
            transfer.statusEnum = MessageStatus.delivered
            transfer.partner = partner
        }
        
        transfer.isOutgoing = isOut
        transfer.partner = partner
        return transfer
    }
    
    func processingComplete(_ transactions: [UInt64]) {
        transactionInProgress.removeAll { trs in
            let contains = transactions.contains(trs)
            if contains {
                if waitSemaphoreCount > 0 {
                    processSemaphore.signal()
                    waitSemaphoreCount -= 1
                }
            }
            return contains
        }        
    }
}
