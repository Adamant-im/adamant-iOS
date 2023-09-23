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
}
