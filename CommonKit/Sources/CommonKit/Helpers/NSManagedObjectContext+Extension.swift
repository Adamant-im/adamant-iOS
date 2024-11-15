//
//  NSManagedObjectContext+Extension.swift
//  
//
//  Created by Andrey Golubenko on 11.08.2023.
//

import CoreData

public extension NSManagedObjectContext {
    func existingObject<T: NSManagedObject>(_ object: T) -> T? {
        try? existingObject(with: object.objectID) as? T
    }
}
