//
//  MessageTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension MessageTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageTransaction> {
        return NSFetchRequest<MessageTransaction>(entityName: "MessageTransaction")
    }

    @NSManaged public var isMarkdown: Bool
    @NSManaged public var message: String?

}
