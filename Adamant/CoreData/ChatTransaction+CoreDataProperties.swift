//
//  ChatTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension ChatTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatTransaction> {
        return NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var height: Int64
    @NSManaged public var message: String?
    @NSManaged public var recipientId: String?
    @NSManaged public var senderId: String?
    @NSManaged public var transactionId: String?
    @NSManaged public var type: Int16
    @NSManaged public var isConfirmed: Bool
    @NSManaged public var chatroom: Chatroom?
    @NSManaged public var lastIn: Chatroom?

}
