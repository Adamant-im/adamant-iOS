//
//  ChatTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension ChatTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatTransaction> {
        return NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
    }

    @NSManaged public var isUnread: Bool
    @NSManaged public var silentNotification: Bool
    @NSManaged public var status: Int16
    @NSManaged public var isConfirmed: Bool
    @NSManaged public var chatroom: Chatroom?
    @NSManaged public var lastIn: Chatroom?

}
