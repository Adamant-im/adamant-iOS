//
//  RichMessageTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData
import CommonKit

@objc(RichMessageTransaction)
public class RichMessageTransaction: ChatTransaction {
    static let entityName = "RichMessageTransaction"
    
    override func serializedMessage() -> String? {
        return richContentSerialized
    }
    
    override var transactionStatus: TransactionStatus? {
        get {
            let data = Data(transactionStatusRaw.utf8)
            return try? JSONDecoder().decode(TransactionStatus.self, from: data)
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let raw = String(data: data, encoding: .utf8)
            else {
                transactionStatusRaw = ""
                return
            }
            
            transactionStatusRaw = raw
        }
    }
    
    var transfer: RichMessageTransfer? {
        guard let richContent = richContent else { return nil }
        return .init(content: richContent)
    }
}
