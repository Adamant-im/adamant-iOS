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
    private let stack: CoreDataStack
    
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

            let chatRequest = NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
            chatRequest.predicate = NSPredicate(format: "transactionId == %@", id)
            chatRequest.fetchLimit = 1
            
            do {
                if let chatTrs = try privateContext.fetch(chatRequest).first {
                    let transactionInContext = privateContext.object(with: transaction.objectID) as? RichMessageTransaction
                    transactionInContext?.chatTransaction = chatTrs
                    chatTrs.addToRichMessageTransactions(transactionInContext!)
                    if privateContext.hasChanges {
                        try privateContext.save()
                    }
                }
                
                return processedIds
            } catch {
                return processedIds
            }
        }
    }
}
