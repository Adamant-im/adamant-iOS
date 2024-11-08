//
//  NSManagedObjectContext+Extension.swift
//  
//
//  Created by Andrey Golubenko on 11.08.2023.
//

import CoreData

public extension NSManagedObjectContext {
    func safeUpdate(action: (NSManagedObjectContext) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self
        action(context)
        try? context.save()
    }
    
    func existingObject<T: NSManagedObject>(_ object: T) -> T? {
        try? existingObject(with: object.objectID) as? T
    }
}
