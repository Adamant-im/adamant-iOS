//
//  InMemoryCoreDataStack.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import CoreData
import Foundation

final class InMemoryCoreDataStack: CoreDataStack {
    let container: NSPersistentContainer

    init(modelUrl url: URL) throws {
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            throw AdamantError(message: "Can't load ManagedObjectModel")
        }

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        container = NSPersistentContainer(name: "Adamant", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, _) in }
        container.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
    }

    func clearCoreData() {
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
