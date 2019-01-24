//
//  BaseAccount+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension BaseAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseAccount> {
        return NSFetchRequest<BaseAccount>(entityName: "BaseAccount")
    }

    @NSManaged public var address: String?
    @NSManaged public var avatar: String?
    @NSManaged public var isSystem: Bool
    @NSManaged public var name: String?
    @NSManaged public var transfers: NSSet?

}

// MARK: Generated accessors for transfers
extension BaseAccount {

    @objc(addTransfersObject:)
    @NSManaged public func addToTransfers(_ value: TransferTransaction)

    @objc(removeTransfersObject:)
    @NSManaged public func removeFromTransfers(_ value: TransferTransaction)

    @objc(addTransfers:)
    @NSManaged public func addToTransfers(_ values: NSSet)

    @objc(removeTransfers:)
    @NSManaged public func removeFromTransfers(_ values: NSSet)

}
