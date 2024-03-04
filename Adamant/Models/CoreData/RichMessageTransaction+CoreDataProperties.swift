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
    
    func isFileReply() -> Bool {
        let replyMessage = richContent?[RichContentKeys.reply.replyMessage] as? [String: Any]
        return replyMessage?[RichContentKeys.file.files] is [[String: Any]]
    }
    
    func getRichValue(for key: String) -> String? {
        if let value = richContent?[key] as? String {
            return value
        }
        
        if let content = richContent?[RichContentKeys.reply.replyMessage] as? [String: Any],
           let value = content[key] as? String {
            return value
        }
        
        return nil
    }
    
    func getRichValue<T>(for key: String) -> T? {
        if let value = richContent?[key] as? T {
            return value
        }
        
        if let content = richContent?[RichContentKeys.file.files] as? [String: Any],
           let value = content[key] as? T {
            return value
        }
        
        if let content = richContent?[RichContentKeys.reply.replyMessage] as? [String: Any],
           let value = content[key] as? T {
            return value
        }
        
        return nil
    }
}
