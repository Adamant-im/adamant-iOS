//
//  CoreDataStack.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CoreData
import Foundation

protocol CoreDataStack: Sendable {
    var container: NSPersistentContainer { get }
    func clearCoreData()
}
