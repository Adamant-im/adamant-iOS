//
//  CoreDataRealationMapper.swift
//  Adamant
//
//  Created by Владимир Клевцов on 24.2.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import CoreData
import CommonKit

protocol CoreDataRealationMapperProtocol {
    func mapReactionRelationship(transaction: RichMessageTransaction) async -> [String]
}

final class CoreDataRealationMapper: CoreDataRealationMapperProtocol {
    let stack: CoreDataStack
    
    init(stack: CoreDataStack) {
        self.stack = stack
    }
    
    func mapReactionRelationship(transaction: RichMessageTransaction) async -> [String] {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        return await privateContext.perform {
            guard let id = transaction.getRichValue(for: RichContentKeys.react.reactto_id) else {
                return []
            }
            
            let processedIds: [String] = [id]

            let messageRequest = NSFetchRequest<MessageTransaction>(entityName: "MessageTransaction")
            messageRequest.predicate = NSPredicate(format: "transactionId == %@", id)
            messageRequest.fetchLimit = 1
            
            let transferRequest = NSFetchRequest<TransferTransaction>(entityName: "TransferTransaction")
            transferRequest.predicate = NSPredicate(format: "transactionId == %@", id)
            transferRequest.fetchLimit = 1
            
            do {
                if let messageTrs = try privateContext.fetch(messageRequest).first {
                    let transactionInContext = privateContext.object(with: transaction.objectID) as? RichMessageTransaction
                    transactionInContext?.messageTransaction = messageTrs
                    messageTrs.addToRichMessageTransactions(transactionInContext!)
                } else if let transferTrs = try privateContext.fetch(transferRequest).first {
                    let transactionInContext = privateContext.object(with: transaction.objectID) as? RichMessageTransaction
                    transactionInContext?.transferTransaction = transferTrs
                    transferTrs.addToRichMessageTransactions(transactionInContext!)
                }
                
                if privateContext.hasChanges {
                    try privateContext.save()
                }
                
                return processedIds
            } catch {
                return processedIds
            }
        }
    }
}
