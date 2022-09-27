//
//  RichMessageTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension RichMessageTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RichMessageTransaction> {
        return NSFetchRequest<RichMessageTransaction>(entityName: "RichMessageTransaction")
    }

    @NSManaged public var richContent: [String:String]?
    @NSManaged public var richType: String?
    @NSManaged public var transferStatusRaw: NSNumber?

}
