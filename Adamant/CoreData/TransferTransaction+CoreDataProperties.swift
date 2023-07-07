//
//  TransferTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension TransferTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransferTransaction> {
        return NSFetchRequest<TransferTransaction>(entityName: "TransferTransaction")
    }

    @NSManaged public var comment: String?
    @NSManaged public var replyToId: String?
    @NSManaged public var decodedReplyMessage: String?
    @NSManaged public var lastReaction: String?
}
