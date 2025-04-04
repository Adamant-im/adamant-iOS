//
//  MessageTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import CoreData
import Foundation

@objc(MessageTransaction)
public class MessageTransaction: ChatTransaction {
    static let entityName = "MessageTransaction"

    override func serializedMessage() -> String? {
        return message
    }
}
