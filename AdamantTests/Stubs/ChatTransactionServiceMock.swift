//
//  ChatTransactionServiceMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CoreData
import CommonKit

final actor ChatTransactionServiceMock: ChatTransactionService {
    func addOperations(_ op: Operation) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func chatTransaction(from transaction: Transaction, isOutgoing: Bool, publicKey: String, privateKey: String, partner: BaseAccount, removedMessages: [String], context: NSManagedObjectContext) -> ChatTransaction? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getTransfer(id: String, context: NSManagedObjectContext) -> TransferTransaction? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func transferTransaction(from transaction: Transaction, isOut: Bool, partner: BaseAccount?, context: NSManagedObjectContext) -> TransferTransaction {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
