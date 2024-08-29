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
    var status: MessageStatus? {
        get {
            let data = Data(statusRaw.utf8)
            return try? JSONDecoder().decode(MessageStatus.self, from: data)
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let raw = String(data: data, encoding: .utf8)
            else {
                statusRaw = ""
                return
            }
            
            statusRaw = raw
        }
    }
    
    func serializedMessage() -> String? {
        fatalError("You must implement serializedMessage in ChatTransaction classes")
    }
    
    var sentDate: Date? {
        date.map { $0 as Date }
    }
    
    override var transactionStatus: TransactionStatus? {
        get {
            return confirmations > 0
            ? .success
            : .pending
        }
        set { }
    }
}
