//
//  BaseTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension BaseTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseTransaction> {
        return NSFetchRequest<BaseTransaction>(entityName: "BaseTransaction")
    }

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var blockId: String?
    @NSManaged public var confirmations: Int64
    @NSManaged public var date: NSDate?
    @NSManaged public var fee: NSDecimalNumber?
    @NSManaged public var height: Int64
    @NSManaged public var isOutgoing: Bool
    @NSManaged public var recipientId: String?
    @NSManaged public var senderId: String?
    @NSManaged public var transactionId: String?
    @NSManaged public var type: Int16

}
