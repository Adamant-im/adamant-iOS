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
            if let raw = transferStatusRaw {
                return TransactionStatus(rawValue: raw.int16Value)
            } else {
                return nil
            }
        }
        set {
            if let raw = newValue {
                transferStatusRaw = raw.rawValue as NSNumber
            } else {
                transferStatusRaw = nil
            }
        }
    }
    
    var transfer: RichMessageTransfer? {
        guard let richContent = richContent else { return nil }
        return .init(content: richContent)
    }
}
