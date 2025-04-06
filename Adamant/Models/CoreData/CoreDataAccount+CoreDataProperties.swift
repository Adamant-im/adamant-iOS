//
//  CoreDataAccount+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

extension CoreDataAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataAccount> {
        return NSFetchRequest<CoreDataAccount>(entityName: "CoreDataAccount")
    }

    @NSManaged public var publicKey: String?
    @NSManaged public var chatroom: Chatroom?

}
