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
import CommonKit

extension RichMessageTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RichMessageTransaction> {
        return NSFetchRequest<RichMessageTransaction>(entityName: "RichMessageTransaction")
    }

    @NSManaged public var richTransferHash: String?
    @NSManaged public var richContentSerialized: String?
    @NSManaged public var richContent: [String: Any]?
    @NSManaged public var richType: String?
    @NSManaged public var transferStatusRaw: NSNumber?
    @NSManaged public var additionalType: RichAdditionalType
    
    func isTransferReply() -> Bool {
        return richContent?[RichContentKeys.reply.replyMessage] is [String: String]
    }
    
    func getRichValue(for key: String) -> String? {
        if let value = richContent?[key] as? String {
            return value
        }
        
        if let content = richContent?[RichContentKeys.reply.replyMessage] as? [String: String],
           let value = content[key] {
            return value
        }
        
        return nil
    }
}
