//
//  CoreDataStack.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataStack {
    var container: NSPersistentContainer { get }
    
    @MainActor func deleteAccounts()
}
