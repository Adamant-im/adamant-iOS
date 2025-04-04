//
//  ChatTransaction+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

extension ChatTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatTransaction> {
        return NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
    }

    @NSManaged public var chatMessageId: String?
    @NSManaged public var isHidden: Bool
    @NSManaged public var isUnread: Bool
    @NSManaged public var showsChatroom: Bool
    @NSManaged public var silentNotification: Bool
    @NSManaged public var status: Int16
    @NSManaged public var chatroom: Chatroom?
    @NSManaged public var lastIn: Chatroom?
    @NSManaged public var isFake: Bool
    @NSManaged public var richMessageTransactions: Set<RichMessageTransaction>?

    func addToRichMessageTransactions(_ transaction: RichMessageTransaction) {
        self.mutableSetValue(forKey: "richMessageTransactions").add(transaction)
    }
}
