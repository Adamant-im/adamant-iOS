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

    @NSManaged public var type: Int16
    @NSManaged public var partner: BaseAccount?
    @NSManaged public var senderPublicKey: String?

}
