//
//  ChatTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ChatTransaction)
public class ChatTransaction: BaseTransaction {
    var statusEnum: MessageStatus {
        get { return MessageStatus(rawValue: self.status) ?? .failed }
        set { self.status = newValue.rawValue }
    }
    
    func serializedMessage() -> String? {
        fatalError("You must implement serializedMessage in ChatTransaction classes")
    }
    
    var sentDate: Date? {
        date.map { $0 as Date }
    }
    
    override var transactionStatus: TransactionStatus? {
        return confirmations > 0
        ? .success
        : .pending
    }
}
