//
//  ChatTransactionService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.10.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CoreData
import CommonKit

// - MARK: SocketService

protocol ChatTransactionService: AnyObject, Actor {
    
    /// Make operations serial
    func addOperations(_ op: Operation)
    
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
    func chatTransaction(from transaction: Transaction, isOutgoing: Bool, publicKey: String, privateKey: String, partner: BaseAccount, removedMessages: [String], context: NSManagedObjectContext) -> ChatTransaction?
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransfer(id: String, context: NSManagedObjectContext) -> TransferTransaction?
    
    /// Create a transaction
    ///
    /// - Parameters:
    ///   - transaction: Transaction
    ///   - isOut: is Out
    ///   - partner: Partner account
    ///   - context: context to insert parsed transaction to
    /// - Returns: Transaction
    func transferTransaction(from transaction: Transaction, isOut: Bool, partner: BaseAccount?, context: NSManagedObjectContext) -> TransferTransaction
    
}
