//
//  InMemoryCoreDataStack.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

final class InMemoryCoreDataStack: CoreDataStack {
    let container: NSPersistentContainer
    
    init(modelUrl url: URL) throws {
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSInMemoryStoreType
        
        container = NSPersistentContainer(name: "Adamant")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, _) in }
        container.viewContext.mergePolicy = NSMergePolicy(
            merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        )
    }
    
    @MainActor func deleteAccounts() {
        let context = container.viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "BaseAccount")
        
        do {
            let result = try context.fetch(fetch)
            for account in result {
                context.delete(account)
            }
            
            try context.save()
        } catch {
            print("Got error saving context after reset")
        }
    }
}
