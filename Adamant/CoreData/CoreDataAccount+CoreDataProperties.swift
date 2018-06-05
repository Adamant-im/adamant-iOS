//
//  CoreDataAccount+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreDataAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataAccount> {
        return NSFetchRequest<CoreDataAccount>(entityName: "CoreDataAccount")
    }

    @NSManaged public var address: String?
    @NSManaged public var avatar: String?
    @NSManaged public var name: String?
    @NSManaged public var publicKey: String?
    @NSManaged public var isSystem: Bool
    @NSManaged public var chatroom: Chatroom?
    @NSManaged public var transfers: NSSet?

}

// MARK: Generated accessors for transfers
extension CoreDataAccount {

    @objc(addTransfersObject:)
    @NSManaged public func addToTransfers(_ value: TransferTransaction)

    @objc(removeTransfersObject:)
    @NSManaged public func removeFromTransfers(_ value: TransferTransaction)

    @objc(addTransfers:)
    @NSManaged public func addToTransfers(_ values: NSSet)

    @objc(removeTransfers:)
    @NSManaged public func removeFromTransfers(_ values: NSSet)

}
