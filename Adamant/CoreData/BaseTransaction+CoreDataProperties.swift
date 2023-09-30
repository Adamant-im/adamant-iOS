//
//  BaseTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension BaseTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseTransaction> {
        return NSFetchRequest<BaseTransaction>(entityName: "BaseTransaction")
    }

    @NSManaged public var blockId: String?
    @NSManaged public var confirmations: Int64
    @NSManaged public var fee: NSDecimalNumber?
    @NSManaged public var height: Int64
    @NSManaged public var isConfirmed: Bool
    @NSManaged public var type: Int16
    @NSManaged public var partner: BaseAccount?
    @NSManaged public var senderPublicKey: String?

}
