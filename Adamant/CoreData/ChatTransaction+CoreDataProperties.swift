//
//  ChatTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData


extension ChatTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatTransaction> {
        return NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
    }

    @NSManaged public var isConfirmed: Bool
    @NSManaged public var message: String?
    @NSManaged public var chatroom: Chatroom?
    @NSManaged public var lastIn: Chatroom?

}
