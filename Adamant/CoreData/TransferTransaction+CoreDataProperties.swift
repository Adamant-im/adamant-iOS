//
//  TransferTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension TransferTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransferTransaction> {
        return NSFetchRequest<TransferTransaction>(entityName: "TransferTransaction")
    }

    @NSManaged public var comment: String?
    @NSManaged public var partner: CoreDataAccount?

}
