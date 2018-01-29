//
//  InMemoryCoreDataStack.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class InMemoryCoreDataStack: CoreDataStack {
	let container: NSPersistentContainer
	
	init(modelUrl url: URL) throws {
		guard let model = NSManagedObjectModel(contentsOf: url) else {
			throw AdamantError(message: "Can't load ManagedObjectModel")
		}
		
		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		
		container = NSPersistentContainer(name: "Adamant", managedObjectModel: model)
		container.persistentStoreDescriptions = [description]
	}
}
