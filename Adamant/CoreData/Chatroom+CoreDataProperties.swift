//
//  Chatroom+CoreDataProperties.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

extension Chatroom {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chatroom> {
        return NSFetchRequest<Chatroom>(entityName: "Chatroom")
    }

    @NSManaged public var hasUnreadMessages: Bool
    @NSManaged public var isForcedVisible: Bool
    @NSManaged public var isHidden: Bool
    @NSManaged public var isReadonly: Bool
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: NSDate?
    @NSManaged public var lastTransaction: ChatTransaction?
    @NSManaged public var partner: CoreDataAccount?
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for transactions
extension Chatroom {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: ChatTransaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: ChatTransaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}
